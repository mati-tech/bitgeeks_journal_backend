from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database import Base, engine
from app.models import Insight, Trade, User  # noqa: F401 — register models with metadata
from app.routers import analytics, auth, insights, trades


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
    yield


app = FastAPI(
    title="Trading Journal API",
    version="0.1.0",
    description="Backend for the AI-powered trading journal.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(trades.router)
app.include_router(analytics.router)
app.include_router(insights.router)

upload_path = Path(settings.UPLOAD_DIR)
upload_path.mkdir(parents=True, exist_ok=True)
app.mount(
    f"/{settings.UPLOAD_DIR.lstrip('./')}",
    StaticFiles(directory=str(upload_path)),
    name="uploads",
)


@app.get("/", tags=["meta"])
def root() -> dict:
    return {"name": "Trading Journal API", "version": "0.1.0", "docs": "/docs"}


@app.get("/health", tags=["meta"])
def health() -> dict:
    return {"status": "ok"}
