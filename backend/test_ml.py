import asyncio
import math

from sqlalchemy import text

from database import SessionLocal
from services.intelligence_service import (
    chat_recommendation,
    smart_dashboard,
    train_model_report,
)
from services.ml_service import (
    analyze_profit,
    classify_dishes,
    generate_suggestions,
    predict_demand,
)


def assert_valid_number(value, label):
    assert isinstance(value, (int, float)), f"{label} is not numeric: {value!r}"
    assert math.isfinite(float(value)), f"{label} is not finite: {value!r}"


async def main():
    db = SessionLocal()
    try:
        restaurant_id = db.execute(text("select id from restaurants limit 1")).scalar()
        if restaurant_id is None:
            raise AssertionError("No restaurant found. Seed or create a restaurant first.")

        demand = predict_demand(restaurant_id, db)
        profit = analyze_profit(restaurant_id, db)
        classifications = classify_dishes(restaurant_id, db)
        suggestions = generate_suggestions(restaurant_id, db)
        report = train_model_report(restaurant_id, db)

        before_records = db.execute(text("select count(*) from prediction_records")).scalar()
        dashboard = smart_dashboard(restaurant_id, db)
        after_first_dashboard = db.execute(text("select count(*) from prediction_records")).scalar()
        smart_dashboard(restaurant_id, db)
        after_second_dashboard = db.execute(text("select count(*) from prediction_records")).scalar()
        chat = await chat_recommendation(
            restaurant_id,
            "What should I prepare next?",
            None,
            db,
        )

        assert demand["predictions"], "Demand model returned no predictions"
        for dish_id, prediction in demand["predictions"].items():
            for key in ("next_day", "next_week"):
                value = prediction[key]
                assert isinstance(value, int), f"{dish_id} {key} is not int: {value!r}"
                assert value >= 0, f"{dish_id} {key} is negative: {value!r}"

        assert profit["analysis"], "Profit analysis returned no rows"
        for row in profit["analysis"]:
            for key in ("unit_cost", "unit_price", "unit_profit", "total_profit", "margin"):
                assert_valid_number(row[key], f"profit.{row['dish_id']}.{key}")

        assert classifications["classifications"], "Classification returned no rows"
        assert dashboard["dish_forecasts"], "Smart dashboard returned no forecasts"
        for row in dashboard["dish_forecasts"]:
            for key in ("expected_quantity", "preparation_quantity", "expected_sales", "margin"):
                assert_valid_number(row[key], f"dashboard.{row['dish_id']}.{key}")
            assert row["expected_quantity"] >= 0
            assert row["preparation_quantity"] >= 0
            assert row["expected_sales"] >= 0

        expected_sales_total = round(
            sum(row["expected_sales"] for row in dashboard["dish_forecasts"]),
            2,
        )
        assert expected_sales_total == dashboard["expected_sales"], (
            f"Dashboard sales total mismatch: rows={expected_sales_total}, "
            f"dashboard={dashboard['expected_sales']}"
        )
        assert after_first_dashboard == after_second_dashboard, (
            "Smart dashboard created duplicate prediction records on repeated runs"
        )
        assert chat["reply"], "Chat returned an empty reply"

        print("ML audit passed")
        print(
            {
                "restaurant_id": restaurant_id,
                "demand_rows": len(demand["predictions"]),
                "profit_rows": len(profit["analysis"]),
                "classification_rows": len(classifications["classifications"]),
                "suggestions": len(suggestions["suggestions"]),
                "model_report": report,
                "prediction_records_before": before_records,
                "prediction_records_after": after_second_dashboard,
                "chat_provider": chat["provider"],
            }
        )
    finally:
        db.close()


if __name__ == "__main__":
    asyncio.run(main())
