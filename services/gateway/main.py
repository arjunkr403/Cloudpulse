import json
import os
import time
from contextlib import asynccontextmanager

import httpx
import jwt
import redis.asyncio as redis
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.responses import Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

load_dotenv()

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
SECRET_KEY = os.getenv("JWT_SECRET", "dev-secret")
HEALTH_SERVICE_URL = os.getenv("HEALTH_SERVICE_URL", "http://localhost:3001")
ALERT_SERVICE_URL = os.getenv("ALERT_SERVICE_URL", "http://localhost:3002")

redis_client = redis.Redis(
    host=REDIS_HOST, port=REDIS_PORT, db=0, decode_responses=True
)

REQUEST_COUNT = Counter(
    "gateway_requests_total", "Total Gateway Requests", ["method", "endpoint"]
)
REQUEST_LATENCY = Histogram(
    "gateway_request_latency_seconds", "Gateway Request Latency", ["endpoint"]
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await redis_client.aclose()


app = FastAPI(title="API Gateway", lifespan=lifespan)


async def verify_token(request: Request):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    token = auth_header.split(" ")[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return payload
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    latency = time.time() - start_time
    REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path).inc()
    REQUEST_LATENCY.labels(endpoint=request.url.path).observe(latency)
    return response


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/api/health")
async def route_health():
    try:
        cached = await redis_client.get("health_status")
        if cached:
            return {"source": "cache", "data": json.loads(cached)}
    except redis.ConnectionError:
        pass

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(f"{HEALTH_SERVICE_URL}/health")
            resp.raise_for_status()
            data = resp.json()
            try:
                await redis_client.setex("health_status", 60, json.dumps(data))
            except redis.ConnectionError:
                pass
            return {"source": "service", "data": data}
        except httpx.HTTPError:
            raise HTTPException(status_code=503, detail="Health service unavailable")


@app.post("/api/alerts")
async def route_alerts(request: Request, _=Depends(verify_token)):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(f"{ALERT_SERVICE_URL}/alerts", json=body)
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPError:
            raise HTTPException(status_code=503, detail="Alert service unavailable")


@app.get("/api/alerts")
async def get_alerts():
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(f"{ALERT_SERVICE_URL}/alerts")
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPError:
            raise HTTPException(status_code=503, detail="Alert service unavailable")


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 3000))
    uvicorn.run(app, host="0.0.0.0", port=port)
