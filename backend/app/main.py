from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from . import models
from .database import engine
from .config import settings
from .routers import (
    auth,
    properties,
    litigation,
    ai_analysis,
    reports,
    alerts,
)

# ---------------------------------------------------------
# Create database tables
# ---------------------------------------------------------

models.Base.metadata.create_all(bind=engine)


# ---------------------------------------------------------
# Seed database
# ---------------------------------------------------------

try:
    from seed_data import run as seed_database

    seed_database()

except Exception as e:
    print(f"❌ Database seeding failed: {e}")


# ---------------------------------------------------------
# FastAPI application
# ---------------------------------------------------------

app = FastAPI(
    title=settings.APP_NAME,
    description=(
        "Unified platform for property legal verification "
        "and AI-driven litigation risk assessment."
    ),
    version="1.0.0",
)


# ---------------------------------------------------------
# CORS
# ---------------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------
# API Routers
# ---------------------------------------------------------

app.include_router(auth.router)
app.include_router(properties.router)
app.include_router(litigation.router)
app.include_router(ai_analysis.router)
app.include_router(reports.router)
app.include_router(alerts.router)


# ---------------------------------------------------------
# Root endpoint
# ---------------------------------------------------------

@app.get("/")
def root():
    return {
        "app": settings.APP_NAME,
        "status": "running",
        "docs": "/docs",
        "websocket": "/ws/alerts",
    }


# ---------------------------------------------------------
# Health endpoint
# ---------------------------------------------------------

@app.get("/health")
def health():
    return {
        "status": "ok"
    }