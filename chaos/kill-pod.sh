#!/bin/bash
# =============================================================
# Chaos Test 1 — Pod Kill
# Deletes a random pod from a deployment and
# watches Kubernetes automatically restart it.
# This proves liveness probes and restart policies work.
# =============================================================

# The service you want to chaos-test. Can Change this to: gateway, alert, frontend
TARGET_SERVICE=${1:-health}

NAMESPACE="cloudpulse"

echo "================================================"
echo "  CHAOS TEST: Pod Kill"
echo "  Target Service: $TARGET_SERVICE"
echo "================================================"

# Step 1: Find the name of the currently running pod for the target service.
# kubectl get pods: lists all pods
# -n $NAMESPACE: in the cloudpulse namespace
# -l app=$TARGET_SERVICE: filter by the label eg.'app=health' (or gateway, etc.)
# -o jsonpath: extract just the pod name from the JSON output
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$TARGET_SERVICE -o jsonpath="{.items[0].metadata.name}")

# If no pod was found, print an error and exit
if [ -z "$POD_NAME" ]; then
  echo "ERROR: No pod found for service '$TARGET_SERVICE' in namespace '$NAMESPACE'"
  echo "Make sure CloudPulse is deployed and the service name is correct."
  exit 1
fi

echo ""
echo "[1/4] Found pod: $POD_NAME"
echo "[2/4] Deleting pod now..."

# Step 2: Delete (kill) the pod.
# Kubernetes sees the pod is gone, compares to the Deployment's desired replica count,
# and immediately schedules a new pod to replace it.
# --grace-period=0: kill it instantly (no graceful shutdown)
kubectl delete pod $POD_NAME -n $NAMESPACE --grace-period=0

echo "[3/4] Pod deleted. Watching Kubernetes recover..."
echo ""

# Step 3: Watch pods in real time -w: watch mode, streams updates as they happen
#We can see the old pod Terminating and a new pod going ContainerCreating -> Running
kubectl get pods -n $NAMESPACE -l app=$TARGET_SERVICE -w &
WATCH_PID=$!

# Step 4: Wait up to 60 seconds for the replacement pod to reach Running state.
# We check every 3 seconds.
echo "[4/4] Waiting for recovery (timeout: 60 seconds)..."
for i in $(seq 1 20); do
  sleep 3
  # Check old pod is gone
  OLD_STILL_EXISTS= $(kubectl get pod $POD_NAME -n $NAMESPACE 2>/dev/null | wc -l)
  # Check expected replica count is fully met
  DESIRED=$(kubectl get deployment $TARGET_SERVICE -n $NAMESPACE -o jsonpath="{.spec.replicas}")
  RUNNING=$(kubectl get pods -n $NAMESPACE -l app=$TARGET_SERVICE --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)


  if [ "$OLD_STILL_EXISTS" -eq "0" ] && [ "$RUNNING" -ge "$DESIRED" ]; then
    echo ""
    echo "================================================"
    echo "  RECOVERY CONFIRMED in ~$((i * 3)) seconds"
    echo "  Pod '$TARGET_SERVICE' is Running again."
    echo "  Self-healing works!"
    echo "================================================"
    # Stop the watch command now that we're done
    kill $WATCH_PID 2>/dev/null
    exit 0
  fi
done

# If we reach here, the pod didn't recover in 60 seconds
echo ""
echo "================================================"
echo "  WARNING: Pod did not recover within 60 seconds."
echo "  Run: kubectl describe pod -n $NAMESPACE -l app=$TARGET_SERVICE"
echo "================================================"
kill $WATCH_PID 2>/dev/null
exit 1
