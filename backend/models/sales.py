from sqlalchemy import Column, Integer, Float, Date, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
from .user import Restaurant
from .menu import Dish

class DailySales(Base):
    __tablename__ = "daily_sales"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"))
    sale_date = Column(Date)
    total_revenue = Column(Float)

    restaurant = relationship("Restaurant", back_populates="daily_sales")
    sales_items = relationship("SalesItem", back_populates="daily_sales")

class SalesItem(Base):
    __tablename__ = "sales_items"

    id = Column(Integer, primary_key=True, index=True)
    daily_sales_id = Column(Integer, ForeignKey("daily_sales.id"))
    dish_id = Column(Integer, ForeignKey("dishes.id"))
    quantity_sold = Column(Integer)
    revenue = Column(Float)

    daily_sales = relationship("DailySales", back_populates="sales_items")
    dish = relationship("Dish", back_populates="sales_items")

    @property
    def dish_name(self):
        return self.dish.name if self.dish else None
