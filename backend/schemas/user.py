from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    firebase_uid: str
    email: str
    name: str

class UserCreate(UserBase):
    pass

class User(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class RestaurantBase(BaseModel):
    name: str
    type: str
    address: str
    phone: str
    email: str = ""
    weather_city: str = ""
    country_code: str = "IN"

class RestaurantCreate(RestaurantBase):
    pass

class Restaurant(RestaurantBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
