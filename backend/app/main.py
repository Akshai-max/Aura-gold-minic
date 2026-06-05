import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings as app_settings
from app.db.session import SessionLocal
from app.services.gold_service import GoldPriceService


async def _gold_price_sync_loop() -> None:
    while True:
        try:
            with SessionLocal() as db:
                GoldPriceService(db).sync_live_price(force=True)
        except Exception as exc:
            print(f"Gold price sync failed: {exc}")
        await asyncio.sleep(app_settings.gold_price_sync_seconds)


@asynccontextmanager
async def lifespan(_: FastAPI):
    sync_task = asyncio.create_task(_gold_price_sync_loop())
    yield
    sync_task.cancel()
    try:
        await sync_task
    except asyncio.CancelledError:
        pass


app = FastAPI(title="AGS API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
