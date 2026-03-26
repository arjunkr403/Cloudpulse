# CloudPulse — Self-Healing Microservices Platform

A microservices platform built phase-by-phase to demonstrate real DevOps practices: containerization, Kubernetes orchestration, Helm packaging, observability, CI/CD, and self-healing chaos engineering.

## Architecture

```text
User (Browser)
    │
    ▼
┌───────────────┐      ┌─────────────────┐
│  Frontend UI  │      │  Grafana Dash   │ ◄── Visualizes Metrics
└───────┬───────┘      └────────┬────────┘
        │                       │
        ▼                       │
┌───────────────┐      ┌────────▼────────┐
│  API Gateway  │ ◄──► │   Prometheus    │ ◄── Scrapes metrics every 15s
└───────┬───────┘      └─────────────────┘
        │                       ▲
   ┌────┴────┐                  │
   ▼         ▼                  │
┌──────┐  ┌──────┐              │
│Health│  │Alert │──────────────┘
└──────┘  └──┬───┘
             │
             ▼
        ┌──────────┐
        │ Database │
        └──────────┘
```

| Service | Language | Port | Role |
|---------|----------|------|------|
| Frontend | React + TypeScript | 80 | Dashboard UI |
| Gateway | Python (FastAPI) | 3000 | API entry point, Redis caching |
| Health | Python (FastAPI) | 3001 | Simulates server health checks |
| Alert | Python (FastAPI) | 3002 | Stores incidents in PostgreSQL |
| Prometheus | — | 9090 | Scrapes and stores metrics |
| Grafana | — | 3000 (NodePort 31300) | Visualizes metrics |

---

## How to Run

**Prerequisites:** Minikube (or Docker Desktop with K8s), Helm, kubectl.

```bash
# 1. Start your cluster
minikube start

# 2. Download Helm dependencies (kube-prometheus-stack)
helm dependency update helm/cloudpulse

# 3. Deploy everything
helm upgrade --install cloudpulse helm/cloudpulse --namespace cloudpulse --create-namespace

# 4. Watch pods come up (takes ~2-3 min for Prometheus)
kubectl get pods -n cloudpulse -w

# 5. Access the frontend
minikube service frontend -n cloudpulse
# or: kubectl port-forward service/frontend 8080:80 -n cloudpulse → localhost:8080
```

---

## Monitoring (Grafana)

```bash
# Open Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n cloudpulse
# Go to http://localhost:3000
# Login: admin / admin-secure
```

Import the dashboard: **Dashboards → New → Import** → upload `dashboards/cloudpulse-overview.json`

You'll see live charts for requests/sec, latency, CPU, and memory.

---

## Load Generator

Simulates traffic and creates fake alerts so Grafana graphs have data to show.

```bash
# Turn on
helm upgrade cloudpulse helm/cloudpulse --namespace cloudpulse --set loadGenerator.enabled=true

# Turn off
helm upgrade cloudpulse helm/cloudpulse --namespace cloudpulse --set loadGenerator.enabled=false
```

---

## Phase 7: Self-Healing Chaos Tests

Phase 7 proves Kubernetes automatically recovers from failures. Three tests are in the `chaos/` folder.

**Make the scripts executable first:**
```bash
chmod +x chaos/*.sh
```

### Test 1 — Pod Kill

Kills a running pod and watches Kubernetes restart it automatically.

```bash
bash chaos/kill-pod.sh health
# also works with: gateway, alert, frontend
```

What to expect: The pod disappears, Kubernetes immediately creates a new one, and within ~15 seconds the service is Running again.

### Test 2 — Service Outage

Scales a service to 0 replicas (simulates it crashing completely), waits 15 seconds, then restores it.

```bash
bash chaos/network-partition.sh alert 15
# args: <service-name> <outage-duration-seconds>
```

What to expect: The alert service goes offline, the gateway returns a 503 error (not a crash), then the service comes back and everything works again.

### Test 3 — Resource Stress (HPA Trigger)

Sends heavy traffic to the gateway for 60 seconds. This pushes CPU usage up on the health pods and triggers the HPA to auto-scale from 2 pods to up to 5.

```bash
# First, open a port-forward in a separate terminal
kubectl port-forward svc/gateway 3000:3000 -n cloudpulse

# Then run the stress test
bash chaos/resource-stress.sh 60
```

What to expect: REPLICAS on the `health-hpa` increases above 2 during the test. After the test ends, Kubernetes scales back down to 2 automatically (~5 min cooldown).

### Run All Three Tests

```bash
bash chaos/run-all.sh
```

---

## CI/CD (Phase 6)

On every push to `main`, GitHub Actions automatically:
1. Lints the Helm chart
2. Builds Docker images for all 4 services
3. Pushes images to Docker Hub tagged `latest` and `sha-<commit>`

**Required GitHub secrets:** `DOCKER_USERNAME`, `DOCKER_PASSWORD`

---

## Project Roadmap

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ Done | Core app — Python services + React frontend |
| Phase 2 | ✅ Done | Docker — Dockerfiles + Compose |
| Phase 3 | ✅ Done | Kubernetes — raw YAML manifests |
| Phase 4 | ✅ Done | Helm — unified chart for all services |
| Phase 5 | ✅ Done | Observability — Prometheus + Grafana |
| Phase 6 | ✅ Done | CI/CD — GitHub Actions build + push pipeline |
| Phase 7 | ✅ Done | Self-healing — chaos tests proving auto-recovery |
