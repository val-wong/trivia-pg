# Trivia API (FastAPI + Postgres)

A simple trivia backend built with **FastAPI** and **Postgres**, containerized with Docker, and deployable on Render.

## Features
- REST API for trivia questions
- CRUD endpoints (create, list, update, delete)
- `/questions/random` and `/questions/search`
- PostgreSQL persistence (via Docker or local)
- Ready-to-deploy with `render.yaml`

## Quickstart
```bash
# 1. Clone
 git clone https://github.com/<your-username>/trivia-pg.git
 cd trivia-pg

# 2. Start Postgres
docker compose up -d db

# 3. Run API locally
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8010

# 4. Seed sample data
python seed_questions.py questions.sample.json

# 5. Try it
curl http://127.0.0.1:8010/healthz
curl http://127.0.0.1:8010/questions/random