#!/bin/bash
# codearts-setup.sh — Script de setup manual para CodeArts
# Correr desde la maquina local o CloudShell
# Requiere: hcloud CLI configurado con AK/SK

set -euo pipefail

echo "=== DummyStore — CodeArts Setup ==="
echo ""
echo "Paso 1: Crear proyecto en la consola"
echo "  Consola HW Cloud → CodeArts → Crear Proyecto"
echo "  Nombre: workshop-dummystore"
echo ""

echo "Paso 2: Crear repos para cada app y pushear codigo"
echo "  CodeArts → Code → Repos → Crear repositorio"
for repo in gateway-api catalog-api orders-api web-ui functiongraph-demo; do
    echo "  - $repo"
done
echo ""

echo "Paso 3: Configurar pipelines"
echo "  CodeArts → Pipelines → Crear pipeline (usar template en codearts/pipeline-template.yaml)"
for app in gateway-api catalog-api orders-api web-ui; do
    echo "  - $app-pipeline (app_name: $app, puerto: ${app##*-})"
done
echo ""

echo "Paso 4: Verificar despliegue en CCE"
echo "  kubectl get pods -n dummystore"
echo "  kubectl get svc -n dummystore"
echo ""

echo "=== Alternativa: despliegue directo desde CLI ==="
echo "Si no hay CodeArts, deploy manual:"
echo "  kubectl create namespace dummystore --dry-run=client -o yaml | kubectl apply -f -"
echo "  kubectl apply -f k8s/"
echo "  kubectl wait --for=condition=available --timeout=120s -n dummystore deployment --all"
echo ""

echo "=== URLs de las apps desplegadas ==="
echo "  Web UI:  http://<ELB-IP>:5000"
echo "  API:     http://<ELB-IP>:9000/api/products"
echo "  Health:  http://<ELB-IP>:9000/health"
