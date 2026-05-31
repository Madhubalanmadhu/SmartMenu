from sqlalchemy.orm import Session
from models.waste import WasteEntry

def get_waste_patterns(restaurant_id: int, db: Session):
    wastes = db.query(WasteEntry).filter(WasteEntry.restaurant_id == restaurant_id).all()
    patterns = {}
    for waste in wastes:
        dish_id = waste.dish_id
        if dish_id not in patterns:
            patterns[dish_id] = {"total_wasted": 0, "reasons": {}}
        patterns[dish_id]["total_wasted"] += waste.quantity_wasted
        reason = waste.reason
        if reason not in patterns[dish_id]["reasons"]:
            patterns[dish_id]["reasons"][reason] = 0
        patterns[dish_id]["reasons"][reason] += waste.quantity_wasted
    return {"patterns": patterns}