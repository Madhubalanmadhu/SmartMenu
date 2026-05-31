from database import SessionLocal
from models.user import User, Restaurant
from models.menu import Category, Dish
from models.sales import DailySales, SalesItem
from models.waste import WasteEntry
from datetime import date, timedelta
import random

def seed_data():
    db = SessionLocal()
    try:
        # Create user
        user = User(firebase_uid="dev-user-123", email="owner@example.com", name="Restaurant Owner")
        db.add(user)
        db.commit()

        # Create restaurant
        restaurant = Restaurant(user_id=user.id, name="Sample Restaurant", type="restaurant", address="123 Main St", phone="1234567890", email="sample@restaurant.com")
        db.add(restaurant)
        db.commit()

        # Create categories
        categories = [
            Category(restaurant_id=restaurant.id, name="Main Course", type="veg"),
            Category(restaurant_id=restaurant.id, name="Beverages", type="drinks"),
            Category(restaurant_id=restaurant.id, name="Desserts", type="veg")
        ]
        for cat in categories:
            db.add(cat)
        db.commit()

        # Create dishes
        dishes = [
            Dish(restaurant_id=restaurant.id, category_id=categories[0].id, name="Butter Chicken", ingredient_cost=150.0, selling_price=250.0),
            Dish(restaurant_id=restaurant.id, category_id=categories[0].id, name="Paneer Tikka", ingredient_cost=120.0, selling_price=200.0),
            Dish(restaurant_id=restaurant.id, category_id=categories[1].id, name="Masala Chai", ingredient_cost=20.0, selling_price=50.0),
            Dish(restaurant_id=restaurant.id, category_id=categories[2].id, name="Ras Malai", ingredient_cost=80.0, selling_price=120.0)
        ]
        for dish in dishes:
            db.add(dish)
        db.commit()

        # Create sales data for last 30 days
        for i in range(30):
            sale_date = date.today() - timedelta(days=i)
            total_revenue = 0
            sales_items = []
            for dish in dishes:
                quantity = random.randint(5, 20)
                revenue = quantity * dish.selling_price
                total_revenue += revenue
                sales_items.append(SalesItem(dish_id=dish.id, quantity_sold=quantity, revenue=revenue))

            daily_sale = DailySales(restaurant_id=restaurant.id, sale_date=sale_date, total_revenue=total_revenue)
            db.add(daily_sale)
            db.commit()
            for item in sales_items:
                item.daily_sales_id = daily_sale.id
                db.add(item)
            db.commit()

        # Create some waste data
        for dish in dishes:
            for i in range(5):
                waste_date = date.today() - timedelta(days=random.randint(0, 30))
                quantity = random.randint(1, 5)
                reason = random.choice(["Expired", "Overcooked", "Leftovers"])
                waste = WasteEntry(dish_id=dish.id, restaurant_id=restaurant.id, waste_date=waste_date, quantity_wasted=quantity, reason=reason)
                db.add(waste)
        db.commit()

        print("Sample data seeded successfully!")

    except Exception as e:
        print(f"Error seeding data: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()
