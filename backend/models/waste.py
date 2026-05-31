from sqlalchemy import Column, Integer, String, Date, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
from .user import Restaurant
from .menu import Dish

class WasteEntry(Base):
    __tablename__ = "waste_entries"

    id = Column(Integer, primary_key=True, index=True)
    dish_id = Column(Integer, ForeignKey("dishes.id"))
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"))
    waste_date = Column(Date)
    quantity_wasted = Column(Integer)
    reason = Column(String)

    dish = relationship("Dish", back_populates="waste_entries")
    restaurant = relationship("Restaurant", back_populates="waste_entries")