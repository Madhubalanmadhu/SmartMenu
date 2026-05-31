from sqlalchemy import Boolean, Column, Date, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from database import Base


class WeatherSnapshot(Base):
    __tablename__ = "weather_snapshots"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), index=True)
    forecast_date = Column(Date, index=True)
    temperature = Column(Float, default=0)
    humidity = Column(Float, default=0)
    rain_probability = Column(Float, default=0)
    condition = Column(String, default="")
    wind_speed = Column(Float, default=0)
    source = Column(String, default="manual")


class CalendarEvent(Base):
    __tablename__ = "calendar_events"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=True, index=True)
    event_date = Column(Date, index=True)
    name = Column(String)
    event_type = Column(String, default="holiday")
    is_public_holiday = Column(Boolean, default=True)
    source = Column(String, default="manual")
    country_code = Column(String, default="")


class PredictionRecord(Base):
    __tablename__ = "prediction_records"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), index=True)
    dish_id = Column(Integer, ForeignKey("dishes.id"), nullable=True, index=True)
    prediction_date = Column(Date, index=True)
    expected_customers = Column(Integer, default=0)
    expected_sales = Column(Float, default=0)
    next_day_quantity = Column(Integer, default=0)
    next_week_quantity = Column(Integer, default=0)
    preparation_quantity = Column(Integer, default=0)
    waste_risk = Column(String, default="low")
    busy_hours = Column(Text, default="[]")
    confidence = Column(String, default="low")
    model_name = Column(String, default="local_ml")

    dish = relationship("Dish")


class InventoryRecipe(Base):
    __tablename__ = "inventory_recipes"

    id = Column(Integer, primary_key=True, index=True)
    dish_id = Column(Integer, ForeignKey("dishes.id"), index=True)
    ingredient_name = Column(String)
    quantity_per_unit = Column(Float, default=0)
    unit = Column(String, default="unit")

    dish = relationship("Dish")
