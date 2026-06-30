#!/bin/bash
# deploy-all.sh — Deploy DummyStore to CCE
set -euo pipefail

NAMESPACE="dummystore"
REGISTRY="swr.la-north-2.myhuaweicloud.com/workshop"

echo "=== Creating namespace ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "=== Applying ConfigMap ==="
kubectl apply -f k8s/ingress-config.yaml

echo "=== Deploying catalog-api ==="
kubectl apply -f k8s/catalog-api.yaml

echo "=== Deploying orders-api ==="
kubectl apply -f k8s/orders-api.yaml

echo "=== Deploying gateway-api ==="
kubectl apply -f k8s/gateway-api.yaml

echo "=== Deploying web-ui ==="
kubectl apply -f k8s/web-ui.yaml

echo "=== Applying HPA ==="
kubectl apply -f k8s/hpa.yaml

echo "=== Waiting for deployments to roll out ==="
for dep in catalog-api orders-api gateway-api web-ui; do
    kubectl rollout status deployment/"$dep" -n "$NAMESPACE" --timeout=120s
done

echo ""
echo "=== Status ==="
kubectl get all -n "$NAMESPACE"
kubectl get hpa -n "$NAMESPACE"

echo ""
echo "=== Done! ==="
echo "Access web-ui at: http://workshop.dummystore.local/"
echo "Access gateway-api at: http://workshop.dummystore.local/api/"
echo ""
echo "To delete everything: kubectl delete namespace $NAMESPACE"
