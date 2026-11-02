# --- Part H: Dashboard for Reporting & Analytics ---
# --- Priamos Koumas & Amanda Gale ---
# --- CS 5200, Fall 2026 ---
#
# A Flask web app that queries the live MySQL database and shows
# key statistics about restaurant visits, revenue, and customers.
#
# AI acknowledgment: built with Claude (Anthropic) as the AI coding
# assistant, as Part H requires. We reviewed and tested the code.

import os
import time
from decimal import Decimal

import pymysql
from dotenv import load_dotenv
from flask import Flask, render_template

load_dotenv()  # reads DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS from .env

app = Flask(__name__)

CACHE_SECONDS = 300
_cache = {"time": 0, "data": None}


def get_connection():
    """Connect to the cloud MySQL database using environment variables."""
    return pymysql.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", 3306)),
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
        cursorclass=pymysql.cursors.DictCursor,
    )


def run_query(cur, sql):
    """Run a query and convert Decimal values to float so they can be sent as JSON."""
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        for key, value in row.items():
            if isinstance(value, Decimal):
                row[key] = float(value)
    return rows


QUERIES = {
    "totals": """
        SELECT COUNT(*)                   AS visits,
               COUNT(DISTINCT v.customerid) AS customers,
               COUNT(DISTINCT v.restaurantid) AS restaurants,
               SUM(b.foodbill)            AS food,
               SUM(b.alcoholbill)         AS alcohol,
               SUM(b.tipamount)           AS tips,
               AVG(v.partysize)           AS avg_party,
               AVG(v.waittime)            AS avg_wait
        FROM visits v
        JOIN bill b ON b.billid = v.billid
    """,
    "by_restaurant": """
        SELECT r.rid,
               r.restaurantname,
               r.city,
               COUNT(v.visitid)             AS visits,
               COUNT(DISTINCT v.customerid) AS customers,
               COALESCE(SUM(b.foodbill), 0)    AS food,
               COALESCE(SUM(b.alcoholbill), 0) AS alcohol,
               COALESCE(SUM(b.tipamount), 0)   AS tips
        FROM restaurants r
        LEFT JOIN visits v ON v.restaurantid = r.rid
        LEFT JOIN bill b   ON b.billid = v.billid
        GROUP BY r.rid, r.restaurantname, r.city
        ORDER BY r.rid
    """,
    "by_month": """
        SELECT DATE_FORMAT(v.visitdate, '%Y-%m') AS month,
               COUNT(*)                          AS visits,
               SUM(b.foodbill + b.alcoholbill)   AS revenue
        FROM visits v
        JOIN bill b ON b.billid = v.billid
        GROUP BY month
        ORDER BY month
    """,
    "by_year": """
        SELECT YEAR(v.visitdate)               AS year,
               COUNT(*)                        AS visits,
               SUM(b.foodbill)                 AS food,
               SUM(b.alcoholbill)              AS alcohol
        FROM visits v
        JOIN bill b ON b.billid = v.billid
        GROUP BY year
        ORDER BY year
    """,
    "by_mealtype": """
        SELECT m.mealtype, COUNT(*) AS visits
        FROM visits v
        JOIN mealtypes m ON m.mtid = v.mtid
        GROUP BY m.mealtype
        ORDER BY visits DESC
    """,
    "by_payment": """
        SELECT p.paymentmethod, COUNT(*) AS bills
        FROM bill b
        JOIN paymentmethods p ON p.pmid = b.pmid
        GROUP BY p.paymentmethod
        ORDER BY bills DESC
    """,
}


def load_data():
    """Run every dashboard query, caching the results for a few minutes."""
    if _cache["data"] is not None and time.time() - _cache["time"] < CACHE_SECONDS:
        return _cache["data"]

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            data = {name: run_query(cur, sql) for name, sql in QUERIES.items()}
    finally:
        conn.close()

    data["totals"] = data["totals"][0]
    _cache["time"] = time.time()
    _cache["data"] = data
    return data


@app.route("/")
def index():
    return render_template("index.html", data=load_data())


if __name__ == "__main__":
    app.run(debug=True, port=5000)
