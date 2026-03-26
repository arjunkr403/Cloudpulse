#!/bin/bash
# =============================================================
# Chaos Test 3 — Resource Stress (HPA Trigger)
# What it does: Runs a heavy, sustained load of HTTP requests
# against the gateway. This pushes CPU usage up on the health
# service pods, which triggers the HPA (Horizontal Pod Autoscaler)
# to automatically scale from 2 pods to up to 5 pods.
# This proves your auto-scaling config actually works.
#
#   kubectl port-forward must be running first:
#   kubectl port-forward svc/gateway 3000:3000 -n cloudpulse
# =============================================================

# How long to run the stress test (seconds)
DURATION=${1:-60}

# How many parallel background curl processes to run at once.
# More = higher CPU load on the pods.
CONCURRENCY=10

NAMESPACE="cloudpulse"

echo "================================================"
echo "  CHAOS TEST: Resource Stress / HPA Trigger"
echo "  Duration   : ${DURATION}s"
echo "  Concurrency: $CONCURRENCY parallel requests"
echo "================================================"
echo ""


# Step 1: Show HPA state BEFORE the test.
# You should see: REPLICAS=2 (at minimum), CPU=low%
echo "[1/4] HPA state BEFORE stress test:"
kubectl get hpa health-hpa -n $NAMESPACE
echo ""

# Step 2: Launch $CONCURRENCY background processes that each loop forever,
# sending GET requests to the gateway as fast as possible.
# This is what drives up CPU usage on the health service pods.
echo "[2/4] Starting stress load ($CONCURRENCY parallel workers for ${DURATION}s)..."

# Store the PIDs of all background workers so we can kill them later
PIDS=()
for i in $(seq 1 $CONCURRENCY); do
  # Each worker: loop, curl, discard output, repeat
  # -s: silent  -o /dev/null: discard body  --max-time 2: 2s timeout per request
  (while true; do curl -s -o /dev/null --max-time 2 http://localhost:3000/api/health; done) &
  PIDS+=($!)  # Save the PID of this background process
done

echo "       $CONCURRENCY workers started. Waiting ${DURATION}s..."
echo "       Watch scaling: kubectl get hpa health-hpa -n $NAMESPACE -w"
echo ""

# Step 3: Poll the HPA every 15 seconds while the stress runs, showing current replica count.
START_TIME=$(date +%s)
while true; do
  ELAPSED=$(( $(date +%s) - START_TIME ))
  if [ $ELAPSED -ge $DURATION ]; then
    break
  fi
  echo "[$(date +%H:%M:%S)] Elapsed: ${ELAPSED}s | HPA status:"
  kubectl get hpa health-hpa -n $NAMESPACE --no-headers 2>/dev/null | \
    awk '{printf "  CPU: %s  |  Replicas: %s/%s\n", $4, $6, $5}'
  sleep 15
done

# Step 4: Kill all background curl workers cleanly
echo ""
echo "[3/4] Stopping stress load..."
for PID in "${PIDS[@]}"; do
  kill $PID 2>/dev/null
done
wait 2>/dev/null
echo "       All workers stopped."
echo ""

# Step 5: Show final HPA state.
# If the test worked, REPLICAS will be > 2 (scaled up).
# After a cooldown period (~5 min by default), K8s will scale back down to 2.
echo "[4/4] HPA state AFTER stress test:"
kubectl get hpa health-hpa -n $NAMESPACE
echo ""
echo "================================================"
echo "  STRESS TEST COMPLETE"
echo "  If REPLICAS increased above 2, HPA worked!"
echo "  K8s will scale back down automatically (~5 min)"
echo "================================================"
