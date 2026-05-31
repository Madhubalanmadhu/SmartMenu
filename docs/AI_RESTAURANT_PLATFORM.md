# AI Restaurant Forecasting Platform

## 1. Architecture Diagram

```text
Flutter App
  | login, menu, sales, analytics, waste, inventory
  v
FastAPI REST API
  | auth | menu | sales | analytics | intelligence | waste
  v
PostgreSQL / SQLite dev DB
  | restaurants, dishes, sales, weather, calendar, predictions, recipes, waste
  v
Local ML Engine
  | pandas feature engineering
  | Multiple Linear Regression for quantities/sales
  | Decision Tree Classifier for waste risk
  v
Recommendation Engine
  | weather rules | weekend/festival rules | margin rules | waste rules
```

## 2. Database Schema

Core tables:
- `users`, `restaurants`
- `categories`, `dishes`
- `daily_sales`, `sales_items`
- `waste_entries`
- `weather_snapshots`
- `calendar_events`
- `prediction_records`
- `inventory_recipes`

`dishes.servings_per_batch` converts batch ingredient cost into unit cost:

```text
unit_cost = ingredient_cost / servings_per_batch
unit_profit = selling_price - unit_cost
margin = unit_profit / selling_price
```

## 3. FastAPI Backend Structure

```text
backend/
  main.py
  database.py
  models/
    intelligence.py
    menu.py
    sales.py
    user.py
    waste.py
  routers/
    analytics.py
    intelligence.py
    menu.py
    sales.py
    waste.py
  services/
    intelligence_service.py
    ml_service.py
    waste_service.py
  schemas/
    intelligence.py
    menu.py
    sales.py
    waste.py
```

## 4. Flutter Frontend Structure

```text
flutter_app/lib/
  screens/
    analytics_screen.dart
    menu_screen.dart
    sales_screen.dart
    waste_screen.dart
  providers/
    analytics_provider.dart
    menu_provider.dart
    sales_provider.dart
  services/
    api_service.dart
  config/
    api_config.dart
```

## 5. ML Workflow Diagram

```text
Sales + Dishes + Weather + Calendar
  -> daily feature frame
  -> feature engineering
  -> regression model predicts quantity
  -> decision tree classifies waste risk
  -> prep quantity + inventory + recommendations
```

## 6. Weather Integration

Endpoint:

```http
POST /intelligence/weather/refresh/{restaurant_id}?city=Chennai
```

Environment keys:

```text
WEATHER_PROVIDER=openweathermap
OPENWEATHER_API_KEY=...
WEATHERAPI_KEY=...
```

If no key is configured, the app uses a baseline weather profile so analytics still works offline.

## 7. Festival Integration

Endpoint:

```http
POST /intelligence/calendar/refresh?country_code=IN&year=2026
```

This uses Nager.Date public holidays. Manual events can be added through:

```http
POST /intelligence/calendar
```

## 8. Model Training Code

Implemented in `backend/services/intelligence_service.py`:
- `train_model_report`
- `_feature_frame`
- `_ml_quantity_prediction`

Regression features:
- dish id
- category id
- day of week
- weekend flag
- month
- season
- temperature
- humidity
- rain probability
- event flag

## 9. Prediction API Example

```http
GET /intelligence/dashboard/1
```

Returns:
- expected customers
- expected sales
- dish forecasts
- hourly forecast
- inventory estimate
- smart recommendations
- model report

## 10. Dashboard UI Suggestions

Implemented panel:
- predicted sales
- expected customers
- weather signal
- calendar signal
- model status
- hourly demand
- smart recommendations
- inventory estimate

Next UI upgrades:
- charts for customer trends
- heatmap for rush hours
- dish ranking cards
- weather/festival detail pages

## 11. Smart Recommendation Logic

Examples:
- rain high -> reduce dine-in prep
- hot weather -> increase beverages
- weekend -> increase lunch/dinner prep
- festival -> increase event-sensitive inventory
- high waste risk -> reduce prep quantity
- low margin -> review price, yield, or portion

## 12. Inventory Forecasting Logic

Add ingredient recipes per dish:

```http
POST /intelligence/inventory/recipes
```

Example:

```json
{
  "dish_id": 5,
  "ingredient_name": "rice",
  "quantity_per_unit": 0.2,
  "unit": "kg"
}
```

If 50 biryanis are predicted, rice estimate is `50 * 0.2 = 10 kg`.

## 13. Sample Dataset Shape

Sales CSV:

```csv
sale_date,dish_name,dish_id,quantity_sold,revenue
2026-05-01,Chicken Biryani,1,14,3500
2026-05-01,Masala Dosa,3,40,2000
```

Weather:

```csv
forecast_date,temperature,humidity,rain_probability,condition,wind_speed
2026-05-13,32,70,60,rain,12
```

## 14. Production Folder Structure

Future production split:

```text
backend/app/
  api/
  core/
  db/
  models/
  schemas/
  services/
  ml/
  integrations/
  tests/
```

## 15. API Integration Examples

Weather refresh:

```bash
curl -X POST "http://127.0.0.1:8000/intelligence/weather/refresh/1?city=Chennai"
```

Smart dashboard:

```bash
curl "http://127.0.0.1:8000/intelligence/dashboard/1"
```

## 16. Implementation Roadmap

Completed:
- batch-aware margin model
- demand forecasting
- weather/calendar-aware intelligence service
- prediction records
- inventory recipes
- smart dashboard API
- Flutter smart analytics panel
- AI food advisor panel

Next:
- PostgreSQL migration files with Alembic
- authenticated intelligence routes
- recipe management UI
- weather/calendar dedicated screens
- chart-based dashboard
- model persistence with joblib
- scheduled retraining

## 17. Deployment Strategy

Backend:
- FastAPI on Render, Railway, Fly.io, or AWS
- PostgreSQL managed DB
- environment variables for Firebase and weather APIs

Frontend:
- Flutter Android/iOS builds
- Firebase Authentication configured per platform

ML:
- train on backend schedule
- keep prediction API real-time
- store prediction snapshots for actual-vs-predicted evaluation
