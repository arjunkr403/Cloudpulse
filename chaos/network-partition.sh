#!/bin/bash
# =============================================================
# Chaos Test 2 — Network Partition (Resource Starvation)
# Scales a deployment DOWN to 0 replicas (simulates
# a service going completely offline), then waits and scales back UP.
# This tests whether dependent services handle the outage gracefully
# (returning errors instead of crashing), and then recover when
# the service comes back.
# =============================================================

# The service to take offline. Options: health, alert, gateway
TARGET_SERVICE=${1:-health}

# How long (in seconds) to keep the service offline
OUTAGE_DURATION=${2:-15}

NAMESPACE="cloudpulse"

echo "================================================"
echo "  CHAOS TEST: Service Outage Simulation"
echo "  Target Service : $TARGET_SERVICE"
echo "  Outage Duration: ${OUTAGE_DURATION}s"
echo "================================================"
echo ""

# Step 1: Show current state before we do anything
echo "[1/5] Current pod state BEFORE outage:"
kubectl get pods -n $NAMESPACE -l app=$TARGET_SERVICE
echo ""

# Step 2: Scale the deployment to 0.
# This removes ALL running pods for this service instantly.
# kubectl scale: changes the replica count of a deployment
# --replicas=0: zero pods = the service is completely down
echo "[2/5] Taking '$TARGET_SERVICE' offline (scaling to 0 replicas)..."
kubectl scale deployment $TARGET_SERVICE -n $NAMESPACE --replicas=0

# Confirm it's gone
echo "       Waiting for pods to terminate..."
kubectl wait --for=delete pod -n $NAMESPACE -l app=$TARGET_SERVICE --timeout=30s 2>/dev/null
echo "       Service is DOWN."
echo ""

# Step 3: While the service is down, hit the gateway to prove it handles the outage gracefully.
echo "[3/5] Testing gateway behavior during outage..."
echo "       Sending request to gateway (expect a 503 or error response)..."

# curl -s: silent mode (no progress bar)
# -o /dev/null: throw away the response body (we only want the status code)
# -w "%{http_code}": print just the HTTP status code
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health 2>/dev/null || echo "unreachable")
echo "       Gateway responded with: HTTP $HTTP_CODE"
echo "       (503 = correct, service handled outage without crashing)"
echo ""

# Step 4: Wait for the configured outage duration
echo "[4/5] Simulating outage for ${OUTAGE_DURATION} seconds..."
sleep $OUTAGE_DURATION

# Step 5: Scale back up to the original replica count.
#for health:replica=2 , for gateway,alert = 1
RESTORE_REPLICAS=2
if [ "$TARGET_SERVICE" != "health" ]; then
  RESTORE_REPLICAS=1
fi

echo "[5/5] Restoring '$TARGET_SERVICE' (scaling back to $RESTORE_REPLICAS replicas)..."
kubectl scale deployment $TARGET_SERVICE -n $NAMESPACE --replicas=$RESTORE_REPLICAS

# Wait until at least one pod is Running again
echo "       Waiting for recovery..."
kubectl wait --for=condition=ready pod -n $NAMESPACE -l app=$TARGET_SERVICE --timeout=60s

echo ""
echo "================================================"
echo "  RECOVERY COMPLETE"
echo "  '$TARGET_SERVICE' is back online."
echo ""
kubectl get pods -n $NAMESPACE -l app=$TARGET_SERVICE
echo "================================================"
