# DummyStore — Workshop CCE + FunctionGraph + CodeArts

Microservicios demo para el workshop de migración del SAT a Huawei Cloud.

## 📦 Apps (4)

| App | Lenguaje | Framework | Puerto | Descripción |
|-----|----------|-----------|--------|-------------|
| `gateway-api` | Python 3.12 | FastAPI | 9000 | API Gateway, enruta a las APIs |
| `catalog-api` | Java 21 | Spring Boot 3 | 8080 | CRUD de productos (in-memory) |
| `orders-api` | Python 3.12 | FastAPI | 8000 | Órdenes de compra |
| `web-ui` | .NET 8 | Blazor Server | 5000 | Frontend web |

## 🔄 FunctionGraph Demo

| Archivo | Descripción |
|---------|-------------|
| `apps/functiongraph-demo/azure-func/index.js` | Azure Function original |
| `apps/functiongraph-demo/huawei-fg/index.js` | Misma lógica, adaptada a Huawei FG |
| `apps/functiongraph-demo/CHEATSHEET.md` | Diferencias sintácticas Azure → Huawei |

## 🏗️ CodeArts Pipeline

| Archivo | Descripción |
|---------|-------------|
| `codearts/project-config.yaml` | Config del proyecto CodeArts |
| `codearts/pipeline-template.yaml` | Template de pipeline CI/CD |
| `scripts/codearts-setup.sh` | Setup guiado |

## 🚀 Local (docker-compose)

```bash
docker compose up --build
```

| App | URL |
|-----|-----|
| Web UI | http://localhost:5000 |
| Gateway API | http://localhost:9000/docs |
| Catalog API | http://localhost:8082/api/products |
| Orders API | http://localhost:8001/orders |
| Health | http://localhost:9000/health |

## ☸️ Deploy a CCE

```bash
# Pushear imagenes locales
docker tag workshop-dummystore-gateway-api:latest swr.la-north-2.myhuaweicloud.com/workshop/gateway-api:latest
docker push swr.la-north-2.myhuaweicloud.com/workshop/gateway-api:latest

# Aplicar manifests
kubectl create namespace dummystore --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s/
kubectl wait --for=condition=available --timeout=120s -n dummystore deployment --all

# Ver
kubectl get all -n dummystore
```

## 🔑 Infraestructura HW Cloud

| Recurso | Nombre | Región |
|---------|--------|--------|
| VPC | `vpc-workshop` (10.0.0.0/16) | la-north-2 |
| Subnet | `subnet-workshop` (10.0.1.0/24) | la-north-2 |
| CCE Cluster | `demo-sat` (K8s v1.35) | la-north-2 |
| SWR | `workshop/*` (4 repos) | la-north-2 |
