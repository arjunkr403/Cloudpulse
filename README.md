# CloudPulse – Self-Healing Microservices Platform

Welcome to **CloudPulse**, a modern, self-healing microservices architecture. 

Currently, the project is in **Phase 1: Core Application**, featuring a Python/FastAPI backend and a React + TypeScript frontend.

## Architecture Overview (Phase 1)

```text
┌─────────────────────────────────────────────────────┐
│                   React TS Frontend                  │
│              (Dashboard + Alerts UI)                 │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP
┌──────────────────────▼──────────────────────────────┐
│              API Gateway (FastAPI :3000)             │
│           Redis Cache (60s TTL on health)            │
└────────┬─────────────────────────────┬──────────────┘
         │                             │
┌────────▼──────────┐      ┌──────────▼──────────────┐
│   Health Service   │      │    Alert Service         │
│   FastAPI :3001    │      │    FastAPI :3002         │
│                    │      │    PostgreSQL (alerts)   │
└────────────────────┘      └─────────────────────────┘
```

### Services Included:
- **`services/gateway` (Port 3000):** Acts as the entry point, handles JWT authentication, provides reverse proxy routes, and uses Redis for caching health statuses.
- **`services/health` (Port 3001):** Exposes system/service health endpoints and generates mock system metrics.
- **`services/alert` (Port 3002):** Connects to PostgreSQL using `asyncpg` to process and store alert events.
- **`frontend` (Port 5173):** React + TypeScript dashboard with Tailwind CSS to view live system health and an alert history table.

All backend services are built with Python (FastAPI) and include a `/metrics` endpoint in Prometheus format.

## Prerequisites

Before running the services, ensure you have the following installed and running locally:
- **Python 3.9+**
- **Node.js 18+**
- **PostgreSQL** (Running on `localhost:5432`, database: `cloudpulse_alerts`, user/pass: `postgres`/`postgres` - *Update `main.py` in alert service if different*)
- **Redis** (Running on `localhost:6379`)

## Installation & Quick Start

Open multiple terminal windows/tabs to start all the components.

### 1. Health Service (Port 3001)
```bash
cd services/health
# Create virtual environment (optional but recommended)
python -m venv venv
# Activate venv: source venv/bin/activate (Linux/Mac) or venv\Scripts\activate (Windows)

pip install -r requirements.txt
python main.py
```

### 2. Alert Service (Port 3002)
```bash
cd services/alert
# Create virtual environment (optional)
python -m venv venv
# Activate venv

pip install -r requirements.txt
python main.py
```

### 3. API Gateway (Port 3000)
```bash
cd services/gateway
# Create virtual environment (optional)
python -m venv venv
# Activate venv

pip install -r requirements.txt
python main.py
```

### 4. Frontend (Port 5173)
```bash
cd frontend
npm install
npm run dev
```

Once everything is running, open your browser and navigate to **[http://localhost:5173](http://localhost:5173)** to view the CloudPulse Dashboard.

## Phase 3: Kubernetes Migration (Completed)

We have migrated the platform from Docker Compose to native Kubernetes manifests.

### Key K8s Features Implemented:
- **Namespace Isolation:** Everything runs in the `cloudpulse` namespace.
- **Secrets & ConfigMaps:** Decoupled configuration from the application code.
- **Persistence:** PostgreSQL uses `PersistentVolumeClaims` to ensure data survives pod restarts.
- **Scaling:** `HorizontalPodAutoscaler` is configured for the `health` service to scale based on CPU.
- **Stability:** `Liveness` and `Readiness` probes are added to every service to ensure the cluster only sends traffic to healthy pods.

### How to Deploy (Phase 3)
1. Start your local cluster (e.g., `minikube start`).
2. (Optional) Point your shell to Minikube's Docker daemon if building images locally: `& minikube -p minikube docker-env --shell powershell | Invoke-Expression`.
3. Apply all manifests:
   ```bash
   kubectl apply -f k8s/base/
   ```
4. Access the Dashboard:
   ```bash
   minikube service frontend -n cloudpulse
   ```

### Next Steps
- **Phase 4:** Helm Charts (Refactoring YAML into templates)
- **Phase 5:** Observability (Prometheus & Grafana)
- **Phase 6:** GitHub Actions CI/CD
- **Phase 7:** Self-Healing Mechanisms
