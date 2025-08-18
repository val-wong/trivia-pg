# Variables
PORT ?= 8010
APP = app.main:app

.PHONY: dev db compose stop clean

## Run FastAPI locally (on PORT)
dev:
	. .venv/bin/activate && uvicorn $(APP) --reload --host 0.0.0.0 --port $(PORT)

## Start Postgres in Docker
db:
	docker compose up -d db

## Run full stack in Docker (API + DB)
compose:
	docker compose up -d --build

## Stop Docker services
stop:
	docker compose down

## Clean volumes (⚠️ nukes DB data)
clean:
	docker compose down -v