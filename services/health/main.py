import os
import random
import time

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.responses import Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, generate_latest

load_dotenv()

app = FastAPI(title="Health Service")

HEALTH_CHECKS = Counter("health_checks_total", "Total Health Checks")
CPU_USAGE = Gauge("system_cpu_usage_percent", "Simulated CPU usage")
MEMORY_USAGE = Gauge("system_memory_usage_percent", "Simulated memory usage")


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/healthz")
async def healthz():
    return {"status": "ok"}


@app.get("/health")
async def get_health():
    HEALTH_CHECKS.inc()

    cpu = random.randint(10, 80)
    memory = random.randint(20, 90)

    CPU_USAGE.set(cpu)
    MEMORY_USAGE.set(memory)

    return {
        "status": "healthy",
        "timestamp": time.time(),
        "services": {"gateway": "up", "health": "up", "alert": "up"},
        "system": {"cpu": cpu, "memory": memory},
    }


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 3001))
    uvicorn.run(app, host="0.0.0.0", port=port)
