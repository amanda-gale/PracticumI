# Restaurant Visits Dashboard (Practicum I, Part H)

Flask web app that reads the live Practicum I MySQL database and shows visits,
revenue, and customer statistics with Chart.js.

## Run locally

1. Install Python 3, then from this folder:
   pip3 install -r requirements.txt
2. Copy .env.example to .env and fill in the database password.
3. Start the app:
   python3 app.py
4. Open http://127.0.0.1:5000

## Host online (Render, free tier)

1. Push this folder to GitHub (the .env file is ignored and stays local).
2. On render.com: New > Web Service > connect the repo.
3. Root directory: dashboard
   Build command: pip install -r requirements.txt
   Start command: gunicorn app:app
4. Under Environment, add DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS.
5. Deploy. Render gives you a public URL.

AI acknowledgment: built with Claude (Anthropic) as the AI coding assistant,
as Part H requires.
