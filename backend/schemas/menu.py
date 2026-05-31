from pydantic import BaseModel
from typing import Optional

class CategoryBase(BaseModel):
    name: str
    type: str

class CategoryCreate(CategoryBase):
    restaurant_id: int

class Category(CategoryBase):
    id: int
    restaurant_id: int

    class Config:
        from_attributes = True

class DishBase(BaseModel):
    name: str
    ingredient_cost: float
    selling_price: float
    servings_per_batch: int = 1
    is_active: bool = True

class DishCreate(DishBase):
    restaurant_id: int
    category_id: int

class Dish(DishBase):
    id: int
    restaurant_id: int
    category_id: int

    class Config:
        from_attributes = True
