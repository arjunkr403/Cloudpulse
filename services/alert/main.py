import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.responses import Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from pydantic import BaseModel
from sqlalchemy import Column, DateTime, Integer, String, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@localhost:5432/cloudpulse_alerts",
)

engine = create_async_engine(DATABASE_URL, echo=False)
async_session = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


class AlertModel(Base):
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String, nullable=False)
    description = Column(String)
    severity = Column(String, nullable=False)
    created_at = Column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )


ALERT_COUNT = Counter("alerts_received_total", "Total Alerts Received", ["severity"])


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    except Exception as e:
        print(f"Warning: Could not connect to database: {e}")
    yield
    await engine.dispose()


app = FastAPI(title="Alert Service", lifespan=lifespan)


class AlertCreate(BaseModel):
    title: str
    description: str
    severity: str


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/alerts")
async def create_alert(alert: AlertCreate):
    ALERT_COUNT.labels(severity=alert.severity).inc()
    try:
        async with async_session() as session:
            new_alert = AlertModel(
                title=alert.title,
                description=alert.description,
                severity=alert.severity,
            )
            session.add(new_alert)
            await session.commit()
            await session.refresh(new_alert)
            return {"id": new_alert.id, "message": "Alert created successfully"}
    except Exception as e:
        print(f"Failed to save alert to DB: {e}")
        return {"id": -1, "message": "Alert received (DB fallback mode)"}


@app.get("/alerts")
async def get_alerts():
    try:
        async with async_session() as session:
            result = await session.execute(
                select(AlertModel).order_by(AlertModel.created_at.desc())
            )
            return result.scalars().all()
    except Exception as e:
        print(f"Failed to fetch alerts from DB: {e}")
        return [
            {
                "id": 1,
                "title": "Fallback Alert",
                "description": "Database connection failed, this is a mock alert.",
                "severity": "warning",
                "created_at": datetime.now(timezone.utc),
            }
        ]


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 3002))
    uvicorn.run(app, host="0.0.0.0", port=port)
