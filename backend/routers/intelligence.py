from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from database import get_db
from models.intelligence import CalendarEvent, InventoryRecipe, WeatherSnapshot
from models.menu import Dish
from routers.auth import get_current_user, require_restaurant_owner
from schemas.intelligence import (
    CalendarEventCreate,
    CalendarEvent as CalendarEventSchema,
    ChatRequest,
    ChatResponse,
    InventoryRecipeCreate,
    InventoryRecipe as InventoryRecipeSchema,
    SmartDashboard,
    WeatherSnapshotCreate,
    WeatherSnapshot as WeatherSnapshotSchema,
)
from services.intelligence_service import (
    chat_recommendation,
    ensure_live_intelligence_context,
    refresh_public_holidays,
    refresh_weather,
    set_weather_city,
    smart_dashboard,
    train_model_report,
    upsert_weather,
)

router = APIRouter()


@router.get("/dashboard/{restaurant_id}", response_model=SmartDashboard)
async def get_smart_dashboard(
    restaurant_id: int,
    prediction_date: date | None = Query(default=None),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(restaurant_id, current_user, db)
    try:
        await ensure_live_intelligence_context(restaurant_id, db, prediction_date)
        return smart_dashboard(restaurant_id, db, prediction_date)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error building smart dashboard: {str(e)}")


@router.post("/chat", response_model=ChatResponse)
async def chat_with_ai(
    request: ChatRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(request.restaurant_id, current_user, db)
    if request.dish_id is not None:
        dish = (
            db.query(Dish)
            .filter(
                Dish.id == request.dish_id,
                Dish.restaurant_id == request.restaurant_id,
            )
            .first()
        )
        if not dish:
            raise HTTPException(status_code=404, detail="Dish not found")
    try:
        return await chat_recommendation(
            request.restaurant_id,
            request.message,
            request.dish_id,
            db,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Error generating AI reply: {str(e)}")


@router.get("/train/{restaurant_id}")
def train_models(
    restaurant_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(restaurant_id, current_user, db)
    try:
        return train_model_report(restaurant_id, db)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error training models: {str(e)}")


@router.post("/weather", response_model=WeatherSnapshotSchema)
def save_weather(
    snapshot: WeatherSnapshotCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(snapshot.restaurant_id, current_user, db)
    return upsert_weather(snapshot.restaurant_id, snapshot.dict(), db)


@router.get("/weather/{restaurant_id}", response_model=list[WeatherSnapshotSchema])
def get_weather_history(
    restaurant_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(restaurant_id, current_user, db)
    return (
        db.query(WeatherSnapshot)
        .filter(WeatherSnapshot.restaurant_id == restaurant_id)
        .order_by(WeatherSnapshot.forecast_date.desc())
        .all()
    )


@router.post("/weather/refresh/{restaurant_id}")
async def refresh_weather_forecast(
    restaurant_id: int,
    city: str,
    prediction_date: date | None = Query(default=None),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(restaurant_id, current_user, db)
    try:
        saved_city = set_weather_city(restaurant_id, city, db)
        return await refresh_weather(restaurant_id, saved_city, db, prediction_date)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Error fetching weather: {str(e)}")


@router.post("/calendar", response_model=CalendarEventSchema)
def save_calendar_event(
    event: CalendarEventCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if event.restaurant_id is not None:
        require_restaurant_owner(event.restaurant_id, current_user, db)
    db_event = CalendarEvent(**event.dict())
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return db_event


@router.get("/calendar/{restaurant_id}", response_model=list[CalendarEventSchema])
def get_calendar_events(
    restaurant_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(restaurant_id, current_user, db)
    return (
        db.query(CalendarEvent)
        .filter((CalendarEvent.restaurant_id == restaurant_id) | (CalendarEvent.restaurant_id.is_(None)))
        .order_by(CalendarEvent.event_date)
        .all()
    )


@router.post("/calendar/refresh")
async def refresh_holidays(
    country_code: str = "IN",
    year: int = date.today().year,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        return {"events": await refresh_public_holidays(country_code, year, db)}
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Error fetching public holidays: {str(e)}")


@router.post("/inventory/recipes", response_model=InventoryRecipeSchema)
def create_inventory_recipe(
    recipe: InventoryRecipeCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    dish = db.query(Dish).filter(Dish.id == recipe.dish_id).first()
    if not dish:
        raise HTTPException(status_code=404, detail="Dish not found")
    require_restaurant_owner(dish.restaurant_id, current_user, db)
    db_recipe = InventoryRecipe(**recipe.dict())
    db.add(db_recipe)
    db.commit()
    db.refresh(db_recipe)
    return db_recipe


@router.get("/inventory/recipes/{dish_id}", response_model=list[InventoryRecipeSchema])
def get_inventory_recipes(
    dish_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not dish:
        raise HTTPException(status_code=404, detail="Dish not found")
    require_restaurant_owner(dish.restaurant_id, current_user, db)
    return db.query(InventoryRecipe).filter(InventoryRecipe.dish_id == dish_id).all()
