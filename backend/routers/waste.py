from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models.menu import Dish
from models.waste import WasteEntry
from routers.auth import get_current_user, require_restaurant_owner
from schemas.waste import WasteEntryCreate, WasteEntry as WasteEntrySchema
from services.waste_service import get_waste_patterns

router = APIRouter()

@router.post("/", response_model=WasteEntrySchema)
def log_waste(
    waste: WasteEntryCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(waste.restaurant_id, current_user, db)
    dish = (
        db.query(Dish)
        .filter(Dish.id == waste.dish_id, Dish.restaurant_id == waste.restaurant_id)
        .first()
    )
    if not dish:
        raise HTTPException(status_code=404, detail="Dish not found")
    db_waste = WasteEntry(**waste.dict())
    db.add(db_waste)
    db.commit()
    db.refresh(db_waste)
    return db_waste

@router.get("/patterns/{restaurant_id}")
def get_patterns(
    restaurant_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    require_restaurant_owner(restaurant_id, current_user, db)
    return get_waste_patterns(restaurant_id, db)
