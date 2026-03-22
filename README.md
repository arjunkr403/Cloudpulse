# CloudPulse – Self-Healing Microservices Platform

Welcome to **CloudPulse**! This is a microservices application built to demonstrate modern DevOps practices. We started with simple code and evolved it into a full-scale Kubernetes platform with monitoring and automation.

Currently, the project has completed **Phase 5: Observability**.

## 🏗️ Architecture Overview

Here is what the system looks like right now running inside Kubernetes:

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
│  API Gateway  │ ◄──► │   Prometheus    │ ◄── Scrapes Metrics (every 15s)
└───────┬───────┘      └─────────────────┘
        │                       ▲
   ┌────┴────┐                  │
   ▼         ▼                  │
┌──────┐  ┌──────┐              │
│Health│  │Alert │ ─────────────┘
└──────┘  └──┬───┘
             │
             ▼
        ┌──────────┐
        │ Database │
        └──────────┘
```

### The Services
- **Frontend:** A React dashboard to view system health and alerts.
- **Gateway:** The entry point for all API requests. It caches data using Redis.
- **Health Service:** Simulates checking the health of servers.
- **Alert Service:** Records incidents in a PostgreSQL database.
- **Monitoring Stack:** Prometheus collects data, and Grafana shows it in charts.

---

## 🚀 How to Run (The Modern Way)

We use **Helm** to deploy everything with one command.

### Prerequisites
1. **Minikube** or Docker Desktop (Kubernetes enabled).
2. **Helm** installed (`choco install kubernetes-helm`).
3. **kubectl** installed.

### Step 1: Start Kubernetes
Make sure your cluster is running:
```bash
minikube start
```

### Step 2: Download Dependencies
We use the official Prometheus charts, so we need to download them first:
```bash
helm dependency update helm/cloudpulse
```

### Step 3: Deploy CloudPulse
Run this command to install the App, Database, Redis, and Monitoring stack:
```bash
helm upgrade --install cloudpulse helm/cloudpulse --namespace cloudpulse --create-namespace
```

Wait a few minutes for all pods (especially Prometheus) to start. You can check progress with:
```bash
kubectl get pods -n cloudpulse -w
```

### Step 4: Access the App
To open the frontend dashboard:
```bash
minikube service frontend -n cloudpulse
```
*(Or use `kubectl port-forward service/frontend 8080:80 -n cloudpulse` and go to localhost:8080)*

---

## 📊 Monitoring & Dashboards

We have set up full observability. Here is how to see it:

1. **Get the Grafana Password:**
   The default user/pass is `admin` / `admin`.

2. **Open Grafana:**
   ```bash
   kubectl port-forward svc/cloudpulse-grafana 3000:80 -n cloudpulse
   ```
   Go to **http://localhost:3000**.

3. **Import Dashboard:**
   - Go to **Dashboards** → **New** → **Import**.
   - Upload the file: `dashboards/cloudpulse-overview.json` (found in this repo).
   - You will see live charts for Traffic, Latency, and CPU usage!

---

## 🧪 Simulation (Load Generator)

Want to see the graphs move? We built a "Load Generator" that simulates traffic and creates fake alerts.

It is **disabled by default**. To turn it on:

```bash
helm upgrade cloudpulse helm/cloudpulse --namespace cloudpulse --set loadGenerator.enabled=true
```

To turn it off:
```bash
helm upgrade cloudpulse helm/cloudpulse --namespace cloudpulse --set loadGenerator.enabled=false
```

---

## 🗺️ Project Roadmap

| Phase | Status | Description |
|-------|--------|-------------|
| **Phase 1** | ✅ Done | **Core App:** Built Python services and React frontend. |
| **Phase 2** | ✅ Done | **Docker:** Containerized everything (Dockerfiles + Compose). |
| **Phase 3** | ✅ Done | **Kubernetes:** Wrote raw YAML manifests for K8s deployment. |
| **Phase 4** | ✅ Done | **Helm Charts:** Created a unified chart for easy deployment. |
| **Phase 5** | ✅ Done | **Observability:** Added Prometheus & Grafana monitoring. |
| **Phase 6** | ⏭️ Next | **CI/CD:** Automate testing and deployment with GitHub Actions. |
| **Phase 7** | 🔜 | **Self-Healing:** Chaos engineering (killing pods to prove recovery). |