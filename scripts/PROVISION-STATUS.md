# Workshop DummyStore — Estado Final
# 2026-06-30

## Infraestructura (la-north-2)

| Recurso | Status | ID |
|---------|--------|-----|
| **VPC** `vpc-workshop` (10.0.0.0/16) | ✅ Creada | `014bbe3c-cb3b-47a3-89c4-1ff1dbc5c2f9` |
| **Subnet** `subnet-workshop` (10.0.1.0/24) | ✅ Creada | `eefff739-09fb-46ff-b07f-4808f3c6b4c8` |
| **CCE Cluster** `demo-sat` (K8s v1.35) | ✅ Creado | `91c0796b-74cd-11f1-a9cd-0255ac1000c7` |
| **SWR** 4 imágenes subidas | ✅ Pusheadas | `swr.la-north-2.myhuaweicloud.com/workshop/*` |

## Apps locales (docker-compose)

| App | Puerto | 
|-----|--------|
| gateway-api (Python FastAPI) | 9000 |
| catalog-api (Java 21 Spring Boot) | 8082 |
| orders-api (Python FastAPI) | 8001 |
| web-ui (.NET 8 Blazor) | 5000 |

## Pendiente para el Viernes

1. **Descargar kubeconfig** desde la consola HW Cloud (CCE → demo-sat → Download Config)
2. Aplicar los manifests: `kubectl apply -f k8s/`
3. Probar acceso vía ELB/Ingress

## Comandos rápidos

```bash
# Ver cluster
kubectl get nodes
kubectl get pods -n dummystore

# Deploy completo
kubectl create namespace dummystore
kubectl apply -f k8s/

# Ver estado
kubectl get all -n dummystore
kubectl get hpa -n dummystore
```
