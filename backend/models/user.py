from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    name = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    restaurants = relationship("Restaurant", back_populates="owner")

class Restaurant(Base):
    __tablename__ = "restaurants"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String)
    type = Column(String)  # e.g., "restaurant", "cafe"
    address = Column(String)
    phone = Column(String)
    email = Column(String, default="")
    weather_city = Column(String, default="")
    country_code = Column(String, default="IN")

    owner = relationship("User", back_populates="restaurants")
    dishes = relationship("Dish", back_populates="restaurant")
    categories = relationship("Category", back_populates="restaurant")
    daily_sales = relationship("DailySales", back_populates="restaurant")
    waste_entries = relationship("WasteEntry", back_populates="restaurant")
