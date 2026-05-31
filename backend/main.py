from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from models import user, menu, sales, waste, intelligence  # Import models to create tables
from routers import auth, menu as menu_router, sales as sales_router, analytics as analytics_router, waste as waste_router, intelligence as intelligence_router
from sqlalchemy import inspect, text

app = FastAPI(title="SmartMenu API", version="1.0.0")

# Create database tables
Base.metadata.create_all(bind=engine)

def ensure_schema_updates():
    inspector = inspect(engine)
    if inspector.has_table("restaurants"):
        restaurant_columns = {column["name"] for column in inspector.get_columns("restaurants")}
        if "email" not in restaurant_columns:
            with engine.begin() as connection:
                connection.execute(text("ALTER TABLE restaurants ADD COLUMN email VARCHAR DEFAULT ''"))
        if "weather_city" not in restaurant_columns:
            with engine.begin() as connection:
                connection.execute(text("ALTER TABLE restaurants ADD COLUMN weather_city VARCHAR DEFAULT ''"))
        if "country_code" not in restaurant_columns:
            with engine.begin() as connection:
                connection.execute(text("ALTER TABLE restaurants ADD COLUMN country_code VARCHAR DEFAULT 'IN'"))

    if inspector.has_table("dishes"):
        dish_columns = {column["name"] for column in inspector.get_columns("dishes")}
        if "servings_per_batch" not in dish_columns:
            with engine.begin() as connection:
                connection.execute(text("ALTER TABLE dishes ADD COLUMN servings_per_batch INTEGER DEFAULT 1"))

    if inspector.has_table("calendar_events"):
        calendar_columns = {column["name"] for column in inspector.get_columns("calendar_events")}
        if "country_code" not in calendar_columns:
            with engine.begin() as connection:
                connection.execute(text("ALTER TABLE calendar_events ADD COLUMN country_code VARCHAR DEFAULT ''"))

ensure_schema_updates()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(menu_router.router, prefix="/menu", tags=["Menu Management"])
app.include_router(sales_router.router, prefix="/sales", tags=["Sales"])
app.include_router(analytics_router.router, prefix="/analytics", tags=["Analytics"])
app.include_router(waste_router.router, prefix="/waste", tags=["Waste Tracking"])
app.include_router(intelligence_router.router, prefix="/intelligence", tags=["AI Intelligence"])

@app.get("/")
async def root():
    return {"message": "SmartMenu API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
