from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from database import get_db
from models.user import User, Restaurant
from services.ml_service import predict_demand, analyze_profit, classify_dishes, generate_suggestions
from routers.auth import require_restaurant_owner, verify_firebase_token

router = APIRouter()

def get_current_user(authorization: str = Header(None)):
    """Dependency to get current user from Authorization header."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid authentication token")
    token = authorization.split(" ")[1]
    decoded = verify_firebase_token(token)
    return decoded

@router.get("/demand/{restaurant_id}")
def get_demand_prediction(restaurant_id: int, current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    require_restaurant_owner(restaurant_id, current_user, db)
    try:
        return predict_demand(restaurant_id, db)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error predicting demand: {str(e)}")

@router.get("/profit/{restaurant_id}")
def get_profit_analysis(restaurant_id: int, current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    require_restaurant_owner(restaurant_id, current_user, db)
    try:
        return analyze_profit(restaurant_id, db)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analyzing profit: {str(e)}")

@router.get("/classify/{restaurant_id}")
def get_dish_classification(restaurant_id: int, current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    require_restaurant_owner(restaurant_id, current_user, db)
    try:
        return classify_dishes(restaurant_id, db)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error classifying dishes: {str(e)}")

@router.get("/suggestions/{restaurant_id}")
def get_ai_suggestions(restaurant_id: int, current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    require_restaurant_owner(restaurant_id, current_user, db)
    try:
        return generate_suggestions(restaurant_id, db)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating suggestions: {str(e)}")
