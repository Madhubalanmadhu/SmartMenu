from pydantic import BaseModel
from datetime import date

class WasteEntryBase(BaseModel):
    dish_id: int
    restaurant_id: int
    waste_date: date
    quantity_wasted: int
    reason: str

class WasteEntryCreate(WasteEntryBase):
    pass

class WasteEntry(WasteEntryBase):
    id: int

    class Config:
        from_attributes = True