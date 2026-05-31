from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"))
    name = Column(String)
    type = Column(String)  # veg/non-veg/drinks

    restaurant = relationship("Restaurant", back_populates="categories")
    dishes = relationship("Dish", back_populates="category")

class Dish(Base):
    __tablename__ = "dishes"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"))
    category_id = Column(Integer, ForeignKey("categories.id"))
    name = Column(String)
    ingredient_cost = Column(Float)
    selling_price = Column(Float)
    servings_per_batch = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)

    restaurant = relationship("Restaurant", back_populates="dishes")
    category = relationship("Category", back_populates="dishes")
    sales_items = relationship("SalesItem", back_populates="dish")
    waste_entries = relationship("WasteEntry", back_populates="dish")
