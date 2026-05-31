from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from database import get_db
from models.sales import DailySales, SalesItem
from models.menu import Category, Dish
from routers.auth import get_current_user, require_restaurant_owner
from schemas.sales import DailySalesCreate, DailySales as DailySalesSchema
import pandas as pd
from io import BytesIO, StringIO
import traceback
import re

router = APIRouter()


DATE_COLUMNS = {"sale_date", "sales_date", "date", "bill_date", "order_date", "day"}
DISH_ID_COLUMNS = {"dish_id", "item_id", "product_id", "menu_id", "id"}
DISH_NAME_COLUMNS = {"dish", "dish_name", "item", "item_name", "product", "product_name", "menu_item", "food", "food_item"}
QUANTITY_COLUMNS = {"quantity_sold", "quantity", "qty", "sold", "units", "count", "no_of_items", "item_count"}
REVENUE_COLUMNS = {"revenue", "amount", "total", "total_amount", "sales", "sale_amount", "price", "value", "net_amount"}

DEFAULT_CATEGORIES = [
    ("Main Course", "main"),
    ("Side Dishes", "side"),
    ("Starters", "starter"),
    ("Breads", "bread"),
    ("Rice & Biryani", "rice"),
    ("Beverages", "drinks"),
    ("Desserts", "dessert"),
    ("Combos", "combo"),
]

CATEGORY_KEYWORDS = [
    ("Rice & Biryani", {"bir", "biryani", "biriyani", "rice", "pulao", "pulav"}),
    ("Breads", {"naan", "roti", "paratha", "chapati", "bread"}),
    ("Beverages", {"tea", "coffee", "juice", "lassi", "shake", "drink", "soda"}),
    ("Desserts", {"sweet", "dessert", "cake", "ice cream", "gulab", "jamun", "payasam", "kheer"}),
    ("Starters", {"starter", "tikka", "kebab", "65", "fry", "roll"}),
    ("Side Dishes", {"side", "salad", "raita", "pickle", "chutney"}),
    ("Combos", {"combo", "meal", "thali"}),
]


def _normalize_column(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", str(value).strip().lower()).strip("_")


def _find_column(columns: set[str], choices: set[str]) -> str | None:
    return next((column for column in columns if column in choices), None)


def _normalize_name(value) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def _ensure_default_categories(restaurant_id: int, db: Session) -> None:
    existing = db.query(Category).filter(Category.restaurant_id == restaurant_id).all()
    existing_names = {category.name.lower() for category in existing}
    for name, category_type in DEFAULT_CATEGORIES:
        if name.lower() not in existing_names:
            db.add(Category(restaurant_id=restaurant_id, name=name, type=category_type))
    db.flush()


def _category_for_uploaded_dish(restaurant_id: int, dish_name: str, db: Session) -> Category:
    _ensure_default_categories(restaurant_id, db)
    categories = db.query(Category).filter(Category.restaurant_id == restaurant_id).all()
    categories_by_name = {category.name.lower(): category for category in categories}
    normalized_name = _normalize_name(dish_name)

    for category_name, keywords in CATEGORY_KEYWORDS:
        if any(keyword in normalized_name for keyword in keywords):
            category = categories_by_name.get(category_name.lower())
            if category:
                return category

    return categories_by_name.get("main course") or categories[0]


def _create_uploaded_dish(
    restaurant_id: int,
    dish_name: str,
    quantity: int,
    revenue: float | None,
    db: Session,
) -> Dish:
    selling_price = 0.0
    if revenue is not None and quantity > 0:
        selling_price = max(0.0, float(revenue) / quantity)

    category = _category_for_uploaded_dish(restaurant_id, dish_name, db)
    dish = Dish(
        restaurant_id=restaurant_id,
        category_id=category.id,
        name=str(dish_name).strip(),
        ingredient_cost=0.0,
        selling_price=selling_price,
        servings_per_batch=1,
        is_active=True,
    )
    db.add(dish)
    db.flush()
    return dish


def _read_sales_upload(file: UploadFile) -> pd.DataFrame:
    filename = (file.filename or "").lower()
    content = file.file.read()
    if filename.endswith(".csv") or filename.endswith(".txt"):
        try:
            return pd.read_csv(StringIO(content.decode("utf-8-sig")))
        except UnicodeDecodeError:
            return pd.read_csv(StringIO(content.decode("latin-1")))
    if filename.endswith((".xlsx", ".xls")):
        return pd.read_excel(BytesIO(content))
    raise HTTPException(status_code=400, detail="Upload a CSV or Excel file (.csv, .xlsx, .xls).")


def _prepare_sales_dataframe(file: UploadFile, restaurant_id: int, db: Session) -> tuple[pd.DataFrame, list[str]]:
    df = _read_sales_upload(file)
    if df.empty:
        raise HTTPException(status_code=400, detail="The uploaded file has no sales rows.")

    df = df.dropna(how="all").copy()
    df.columns = [_normalize_column(column) for column in df.columns]
    columns = set(df.columns)

    date_col = _find_column(columns, DATE_COLUMNS)
    dish_id_col = _find_column(columns, DISH_ID_COLUMNS)
    dish_name_col = _find_column(columns, DISH_NAME_COLUMNS)
    quantity_col = _find_column(columns, QUANTITY_COLUMNS)
    revenue_col = _find_column(columns, REVENUE_COLUMNS)

    missing = []
    if date_col is None:
        missing.append("date")
    if dish_id_col is None and dish_name_col is None:
        missing.append("dish name or dish id")
    if quantity_col is None:
        missing.append("quantity")
    if missing:
        raise HTTPException(
            status_code=400,
            detail="Please upload a valid sales file.",
        )

    dishes = db.query(Dish).filter(Dish.restaurant_id == restaurant_id).all()
    dishes_by_id = {dish.id: dish for dish in dishes}
    dishes_by_name = {_normalize_name(dish.name): dish for dish in dishes}

    prepared_rows = []
    unmatched_dishes = set()
    created_dishes = set()
    invalid_rows = []
    for index, row in df.iterrows():
        sale_date = pd.to_datetime(row.get(date_col), errors="coerce")
        quantity = pd.to_numeric(row.get(quantity_col), errors="coerce")
        if pd.isna(sale_date) or pd.isna(quantity) or int(quantity) <= 0:
            invalid_rows.append(index + 2)
            continue

        quantity_value = int(quantity)
        revenue = pd.to_numeric(row.get(revenue_col), errors="coerce") if revenue_col else None
        revenue_value = None if revenue is None or pd.isna(revenue) else float(revenue)

        dish = None
        raw_name = row.get(dish_name_col) if dish_name_col is not None else None
        dish_name = str(raw_name).strip() if raw_name is not None and pd.notna(raw_name) else ""

        if dish_name:
            dish = dishes_by_name.get(_normalize_name(dish_name))

        if dish is None and dish_id_col is not None and pd.notna(row.get(dish_id_col)):
            dish_id_value = pd.to_numeric(row.get(dish_id_col), errors="coerce")
            if pd.notna(dish_id_value):
                dish = dishes_by_id.get(int(dish_id_value))

        if dish is None and dish_name:
            dish = _create_uploaded_dish(
                restaurant_id,
                dish_name,
                quantity_value,
                revenue_value,
                db,
            )
            dishes_by_id[dish.id] = dish
            dishes_by_name[_normalize_name(dish.name)] = dish
            created_dishes.add(dish.name)

        if dish is None:
            if dish_id_col is not None:
                unmatched_dishes.add(str(row.get(dish_id_col)).strip())
            continue

        if revenue_value is None:
            revenue_value = float(dish.selling_price or 0) * quantity_value

        prepared_rows.append(
            {
                "sale_date": sale_date.date(),
                "dish_id": dish.id,
                "quantity_sold": quantity_value,
                "revenue": float(revenue_value),
            }
        )

    if unmatched_dishes:
        examples = ", ".join(sorted(list(unmatched_dishes))[:8])
        raise HTTPException(
            status_code=400,
            detail=f"Could not match these dishes to your menu: {examples}. Use the exact menu name or dish ID.",
        )

    if not prepared_rows:
        raise HTTPException(status_code=400, detail="No valid sales rows found in the uploaded file.")

    sales_df = pd.DataFrame(prepared_rows)
    sales_df = (
        sales_df.groupby(["sale_date", "dish_id"], as_index=False)
        .agg({"quantity_sold": "sum", "revenue": "sum"})
    )
    warnings = []
    if invalid_rows:
        warnings.append(f"Skipped {len(invalid_rows)} row(s) with missing/invalid date or quantity.")
    if revenue_col is None:
        warnings.append("Revenue was calculated from menu selling price because no amount column was found.")
    if created_dishes:
        examples = ", ".join(sorted(created_dishes)[:8])
        warnings.append(f"Created {len(created_dishes)} new menu dish(es) from the upload: {examples}.")
        warnings.append("Add ingredient costs for new dishes in Menu so profit margins are calculated.")
    return sales_df, warnings

@router.post("/daily", response_model=DailySalesSchema)
def create_daily_sales(
    sales: DailySalesCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(sales.restaurant_id, current_user, db)
    dish_ids = {item.dish_id for item in sales.sales_items}
    dish_count = (
        db.query(Dish)
        .filter(Dish.restaurant_id == sales.restaurant_id, Dish.id.in_(dish_ids))
        .count()
        if dish_ids
        else 0
    )
    if dish_count != len(dish_ids):
        raise HTTPException(status_code=404, detail="One or more dishes were not found")
    db_sales = (
        db.query(DailySales)
        .filter(
            DailySales.restaurant_id == sales.restaurant_id,
            DailySales.sale_date == sales.sale_date,
        )
        .first()
    )
    if not db_sales:
        db_sales = DailySales(
            restaurant_id=sales.restaurant_id,
            sale_date=sales.sale_date,
            total_revenue=0,
        )
        db.add(db_sales)
        db.flush()

    for item in sales.sales_items:
        db_item = (
            db.query(SalesItem)
            .filter(
                SalesItem.daily_sales_id == db_sales.id,
                SalesItem.dish_id == item.dish_id,
            )
            .first()
        )
        if not db_item:
            db_item = SalesItem(
                daily_sales_id=db_sales.id,
                dish_id=item.dish_id,
            )
            db.add(db_item)
        db_item.quantity_sold = item.quantity_sold
        db_item.revenue = item.revenue

    db.flush()
    db_sales.total_revenue = sum(item.revenue or 0 for item in db_sales.sales_items)
    db.commit()
    db.refresh(db_sales)
    return db_sales

@router.post("/upload-csv")
def upload_csv(
    file: UploadFile = File(...),
    restaurant_id: int = None,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if restaurant_id is None:
        raise HTTPException(status_code=400, detail="restaurant_id query parameter is required")
    require_restaurant_owner(restaurant_id, current_user, db)
    try:
        df, warnings = _prepare_sales_dataframe(file, restaurant_id, db)
        rows_processed = 0
        dates_touched = 0
        touched_dates = []
        for sale_date, group in df.groupby('sale_date'):
            db_sales = (
                db.query(DailySales)
                .filter(
                    DailySales.restaurant_id == restaurant_id,
                    DailySales.sale_date == sale_date,
                )
                .first()
            )
            if not db_sales:
                db_sales = DailySales(
                    restaurant_id=restaurant_id,
                    sale_date=sale_date,
                    total_revenue=0,
                )
                db.add(db_sales)
            db.flush()

            for _, row in group.iterrows():
                db_item = (
                    db.query(SalesItem)
                    .filter(
                        SalesItem.daily_sales_id == db_sales.id,
                        SalesItem.dish_id == int(row['dish_id']),
                    )
                    .first()
                )
                if not db_item:
                    db_item = SalesItem(
                        daily_sales_id=db_sales.id,
                        dish_id=int(row['dish_id']),
                    )
                    db.add(db_item)
                db_item.quantity_sold = int(row['quantity_sold'])
                db_item.revenue = float(row['revenue'])
                rows_processed += 1

            db.flush()
            db_sales.total_revenue = sum(item.revenue or 0 for item in db_sales.sales_items)
            dates_touched += 1
            touched_dates.append(sale_date.isoformat())
        db.commit()
        message = f"Uploaded {rows_processed} item row(s) across {dates_touched} sale date(s)."
        if warnings:
            message = f"{message} {' '.join(warnings)}"
        return {
            "message": message,
            "rows_processed": rows_processed,
            "dates_touched": dates_touched,
            "touched_dates": touched_dates,
            "warnings": warnings,
        }
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error processing CSV: {str(e)}")

@router.get("/history/{restaurant_id}", response_model=list[DailySalesSchema])
def get_sales_history(
    restaurant_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(restaurant_id, current_user, db)
    return (
        db.query(DailySales)
        .filter(DailySales.restaurant_id == restaurant_id)
        .order_by(DailySales.sale_date.desc(), DailySales.id.desc())
        .all()
    )
