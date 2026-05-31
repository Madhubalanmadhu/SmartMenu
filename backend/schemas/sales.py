from pydantic import BaseModel
from typing import List, Optional
from datetime import date

class SalesItemBase(BaseModel):
    dish_id: int
    quantity_sold: int
    revenue: float

class SalesItemCreate(SalesItemBase):
    pass

class SalesItem(SalesItemBase):
    id: int
    daily_sales_id: int
    dish_name: Optional[str] = None

    class Config:
        from_attributes = True

class DailySalesBase(BaseModel):
    sale_date: date
    total_revenue: float

class DailySalesCreate(DailySalesBase):
    restaurant_id: int
    sales_items: List[SalesItemCreate]

class DailySales(DailySalesBase):
    id: int
    restaurant_id: int
    sales_items: List[SalesItem]

    class Config:
        from_attributes = True
