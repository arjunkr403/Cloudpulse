#!/bin/bash
# =============================================================
# Full Chaos Suite
#
# Tests run in this order:
#   1. Pod Kill      — kills health pod, watches Kubernetes restart it
#   2. Network Part. — takes alert service offline, then restores it
#   3. Resource Stress — floods gateway to trigger HPA autoscaling
#
# Run from the project root:
#   bash chaos/run-all.sh
# =============================================================

CHAOS_DIR="$(dirname "$0")"
NAMESPACE="cloudpulse"
PAUSE=10  # seconds to wait between tests

# Make all scripts executable
chmod +x "$CHAOS_DIR/kill-pod.sh"
chmod +x "$CHAOS_DIR/network-partition.sh"
chmod +x "$CHAOS_DIR/resource-stress.sh"

echo ""
echo "###################################################"
echo "#           CLOUDPULSE FULL CHAOS SUITE           #"
echo "###################################################"
echo ""

# Verify cluster is reachable before starting
if ! kubectl get ns $NAMESPACE &>/dev/null; then
  echo "ERROR: Cannot reach Kubernetes namespace '$NAMESPACE'."
  echo "Make sure your cluster is running and CloudPulse is deployed."
  exit 1
fi

echo "Cluster check passed. Starting chaos tests..."
echo ""

# -------------------------------------------------------
# TEST 1: Pod Kill
# -------------------------------------------------------
echo "###################################################"
echo "# TEST 1/3: Pod Kill (health service)            #"
echo "###################################################"
bash "$CHAOS_DIR/kill-pod.sh" health
echo ""
echo "Pausing ${PAUSE}s before next test..."
sleep $PAUSE

# -------------------------------------------------------
# TEST 2: Network Partition (Service Outage)
# -------------------------------------------------------
echo "###################################################"
echo "# TEST 2/3: Service Outage (alert service)       #"
echo "###################################################"
bash "$CHAOS_DIR/network-partition.sh" alert 15
echo ""
echo "Pausing ${PAUSE}s before next test..."
sleep $PAUSE

# -------------------------------------------------------
# TEST 3: Resource Stress / HPA Trigger
# -------------------------------------------------------
echo "###################################################"
echo "# TEST 3/3: Resource Stress (HPA trigger)        #"
echo "###################################################"
echo ""
echo "NOTE: This test requires port-forward to be running:"
echo "  kubectl port-forward svc/gateway 3000:3000 -n cloudpulse"
echo ""
read -p "Is port-forward running? (y/n): " PF_CONFIRM
if [ "$PF_CONFIRM" = "y" ] || [ "$PF_CONFIRM" = "Y" ]; then
  bash "$CHAOS_DIR/resource-stress.sh" 60
else
  echo "Skipping resource stress test."
fi

# -------------------------------------------------------
# Final summary
# -------------------------------------------------------
echo ""
echo "###################################################"
echo "#   ALL CHAOS TESTS COMPLETE                     #"
echo "#                                                #"
echo "#   Final cluster state:                         #"
kubectl get pods -n $NAMESPACE --no-headers | \
  awk '{printf "#     %-40s %s\n", $1, $3}'
echo "#                                                #"
echo "###################################################"
echo ""
