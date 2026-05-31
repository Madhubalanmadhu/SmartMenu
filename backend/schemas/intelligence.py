from datetime import date
from typing import Any, List, Optional
from pydantic import BaseModel


class WeatherSnapshotBase(BaseModel):
    forecast_date: date
    temperature: float = 0
    humidity: float = 0
    rain_probability: float = 0
    condition: str = ""
    wind_speed: float = 0
    source: str = "manual"


class WeatherSnapshotCreate(WeatherSnapshotBase):
    restaurant_id: int


class WeatherSnapshot(WeatherSnapshotBase):
    id: int
    restaurant_id: int

    class Config:
        from_attributes = True


class CalendarEventBase(BaseModel):
    event_date: date
    name: str
    event_type: str = "holiday"
    is_public_holiday: bool = True
    source: str = "manual"
    country_code: str = ""


class CalendarEventCreate(CalendarEventBase):
    restaurant_id: Optional[int] = None


class CalendarEvent(CalendarEventBase):
    id: int
    restaurant_id: Optional[int] = None

    class Config:
        from_attributes = True


class InventoryRecipeBase(BaseModel):
    ingredient_name: str
    quantity_per_unit: float
    unit: str = "unit"


class InventoryRecipeCreate(InventoryRecipeBase):
    dish_id: int


class InventoryRecipe(InventoryRecipeBase):
    id: int
    dish_id: int

    class Config:
        from_attributes = True


class SmartDashboard(BaseModel):
    prediction_date: date
    expected_customers: int
    expected_sales: float
    weather_city: Optional[str] = None
    weather: dict[str, Any]
    calendar: dict[str, Any]
    dish_forecasts: List[dict[str, Any]]
    hourly_forecast: List[dict[str, Any]]
    inventory_estimate: List[dict[str, Any]]
    recommendations: List[dict[str, Any]]
    model_report: dict[str, Any]


class ChatRequest(BaseModel):
    restaurant_id: int
    message: str
    dish_id: Optional[int] = None


class ChatResponse(BaseModel):
    reply: str
    provider: str
    context: dict[str, Any]
