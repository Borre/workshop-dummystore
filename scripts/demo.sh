#!/bin/bash
# demo.sh — Workshop demo script for SAT apps team
# Run this step-by-step during the workshop

set -e

DEMO_NAMESPACE="dummystore"
GATEWAY_URL="http://gateway-api:9000"
CATALOG_URL="http://catalog-api:8080"
ORDERS_URL="http://orders-api:8000"
WEBUI_URL="http://web-ui:5000"

echo "========================================"
echo "  DummyStore Workshop — Demo Script"
echo "  SAT Apps Team · Huawei Cloud CCE"
echo "========================================"

step() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  STEP $1: $2"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

pause() {
    echo ""
    echo "  ⏸ Press ENTER to continue..."
    read -r
}

# =====================
# STEP 1: Pre-requisites
# =====================
step 1 "Verify environment"
echo "  kubectl version............... $(kubectl version --short 2>/dev/null | head -1)"
echo "  Namespace...................."
kubectl get ns "$DEMO_NAMESPACE" --no-headers 2>/dev/null || echo "  (will be created)"
echo ""
echo "  Services to deploy:"
echo "  - catalog-api (Java 21, Spring Boot, :8080)"
echo "  - orders-api  (Python 3.12, FastAPI, :8000)"
echo "  - gateway-api (Python 3.12, FastAPI, :9000)"
echo "  - web-ui      (.NET 8, Blazor, :5000)"
pause

# =====================
# STEP 2: Deploy
# =====================
step 2 "Deploy to CCE"
echo "  Creating namespace..."
kubectl create namespace "$DEMO_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
echo "  ✅ Namespace ready"

echo ""
echo "  Applying manifests..."
kubectl apply -f k8s/
echo "  ✅ All manifests applied"

echo ""
echo "  Waiting for pods..."
kubectl wait --for=condition=available --timeout=120s -n "$DEMO_NAMESPACE" deployment/catalog-api
kubectl wait --for=condition=available --timeout=120s -n "$DEMO_NAMESPACE" deployment/orders-api
kubectl wait --for=condition=available --timeout=120s -n "$DEMO_NAMESPACE" deployment/gateway-api
kubectl wait --for=condition=available --timeout=120s -n "$DEMO_NAMESPACE" deployment/web-ui
echo "  ✅ All pods running"
pause

# =====================
# STEP 3: Verify
# =====================
step 3 "Verify services"
echo "  Pods:"
kubectl get pods -n "$DEMO_NAMESPACE" -o wide

echo ""
echo "  Services:"
kubectl get svc -n "$DEMO_NAMESPACE"

echo ""
echo "  HPA:"
kubectl get hpa -n "$DEMO_NAMESPACE"
pause

# =====================
# STEP 4: Test catalog API
# =====================
step 4 "Test catalog API (Java)"
echo "  Getting products..."
kubectl exec -n "$DEMO_NAMESPACE" deploy/gateway-api -- curl -s http://catalog-api:8080/api/products | head -20

echo ""
echo "  Getting single product..."
kubectl exec -n "$DEMO_NAMESPACE" deploy/gateway-api -- curl -s http://catalog-api:8080/api/products/1

echo ""
echo "  Health check..."
kubectl exec -n "$DEMO_NAMESPACE" deploy/gateway-api -- curl -s http://catalog-api:8080/health
pause

# =====================
# STEP 5: Test orders API
# =====================
step 5 "Test orders API (Python)"
echo "  Creating order..."
kubectl exec -n "$DEMO_NAMESPACE" deploy/gateway-api -- curl -s -X POST http://orders-api:8000/orders \
  -H "Content-Type: application/json" \
  -d '{"product_id":1,"quantity":2,"customer":"SAT Demo"}'

echo ""
echo "  Listing orders..."
kubectl exec -n "$DEMO_NAMESPACE" deploy/gateway-api -- curl -s http://orders-api:8000/orders
pause

# =====================
# STEP 6: Scale demo
# =====================
step 6 "Scaling demo"
echo "  Current replicas:"
kubectl get deploy -n "$DEMO_NAMESPACE" -o custom-columns=NAME:.metadata.name,REPLICAS:.status.replicas

echo ""
echo "  Scaling catalog-api to 4 replicas..."
kubectl scale -n "$DEMO_NAMESPACE" deploy/catalog-api --replicas=4
echo "  Waiting..."
kubectl wait --for=condition=available --timeout=30s -n "$DEMO_NAMESPACE" deployment/catalog-api

echo ""
echo "  New replicas:"
kubectl get pods -n "$DEMO_NAMESPACE" -l app=catalog-api

echo ""
echo "  Scaling back to 2..."
kubectl scale -n "$DEMO_NAMESPACE" deploy/catalog-api --replicas=2
pause

# =====================
# STEP 7: Logs & metrics
# =====================
step 7 "Logs & metrics (AOM)"
echo "  Recent logs from catalog-api:"
kubectl logs -n "$DEMO_NAMESPACE" -l app=catalog-api --tail=10

echo ""
echo "  AOM metrics available at:"
echo "  https://console.huaweicloud.com/aom/"
pause

# =====================
# STEP 8: Rollback
# =====================
step 8 "Rollback demo"
echo "  Deployment history:"
kubectl rollout history -n "$DEMO_NAMESPACE" deployment/catalog-api

echo ""
echo "  Current image:"
kubectl get deploy -n "$DEMO_NAMESPACE" catalog-api -o jsonpath='{.spec.template.spec.containers[0].image}'

echo ""
echo "  To rollback:"
echo "  kubectl rollout undo -n $DEMO_NAMESPACE deployment/catalog-api"
echo "  kubectl rollout status -n $DEMO_NAMESPACE deployment/catalog-api"
pause

# =====================
# DONE
# =====================
echo ""
echo "========================================"
echo "  ✅ Workshop demo complete!"
echo "========================================"
echo ""
echo "  Architecture:"
echo "  web-ui (.NET) ──▶ gateway-api (Python) ──▶ catalog-api (Java)"
echo "                                         ──▶ orders-api (Python)"
echo ""
echo "  Service discovery: K8s DNS (svc.cluster.local)"
echo "  Autoscaling: HPA (target CPU 60-70%)"
echo "  Logs: AOM / LTS"
echo ""
echo "  Cleanup: kubectl delete namespace $DEMO_NAMESPACE"
