from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models.menu import Dish, Category
from routers.auth import get_current_user, require_restaurant_owner
from schemas.menu import DishCreate, Dish as DishSchema, CategoryCreate, Category as CategorySchema

router = APIRouter()

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

def ensure_default_categories(restaurant_id: int, db: Session):
    existing = db.query(Category).filter(Category.restaurant_id == restaurant_id).all()
    existing_names = {category.name.lower() for category in existing}
    added = False
    for name, category_type in DEFAULT_CATEGORIES:
        if name.lower() not in existing_names:
            db.add(Category(restaurant_id=restaurant_id, name=name, type=category_type))
            added = True
    if added:
        db.commit()

@router.post("/categories", response_model=CategorySchema)
def create_category(
    category: CategoryCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(category.restaurant_id, current_user, db)
    db_category = Category(**category.dict())
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

@router.get("/categories/{restaurant_id}", response_model=list[CategorySchema])
def get_categories(
    restaurant_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(restaurant_id, current_user, db)
    ensure_default_categories(restaurant_id, db)
    return db.query(Category).filter(Category.restaurant_id == restaurant_id).all()

@router.post("/dishes", response_model=DishSchema)
def create_dish(
    dish: DishCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(dish.restaurant_id, current_user, db)
    category = (
        db.query(Category)
        .filter(
            Category.id == dish.category_id,
            Category.restaurant_id == dish.restaurant_id,
        )
        .first()
    )
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    dish_data = dish.dict()
    dish_data["servings_per_batch"] = max(1, dish_data.get("servings_per_batch") or 1)
    db_dish = Dish(**dish_data)
    db.add(db_dish)
    db.commit()
    db.refresh(db_dish)
    return db_dish

@router.get("/dishes/{restaurant_id}", response_model=list[DishSchema])
def get_dishes(
    restaurant_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(restaurant_id, current_user, db)
    return db.query(Dish).filter(Dish.restaurant_id == restaurant_id).all()

@router.put("/dishes/{dish_id}", response_model=DishSchema)
def update_dish(
    dish_id: int,
    dish: DishCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db_dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not db_dish:
        raise HTTPException(status_code=404, detail="Dish not found")
    require_restaurant_owner(db_dish.restaurant_id, current_user, db)
    if dish.restaurant_id != db_dish.restaurant_id:
        raise HTTPException(status_code=400, detail="Dish restaurant cannot be changed")
    category = (
        db.query(Category)
        .filter(
            Category.id == dish.category_id,
            Category.restaurant_id == db_dish.restaurant_id,
        )
        .first()
    )
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    for key, value in dish.dict().items():
        setattr(db_dish, key, value)
    db.commit()
    db.refresh(db_dish)
    return db_dish

@router.delete("/dishes/{dish_id}")
def delete_dish(
    dish_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db_dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not db_dish:
        raise HTTPException(status_code=404, detail="Dish not found")
    require_restaurant_owner(db_dish.restaurant_id, current_user, db)
    db.delete(db_dish)
    db.commit()
    return {"message": "Dish deleted"}
