# Azure Function → Huawei FunctionGraph: Migration Cheat Sheet
# Para el workshop del Viernes — DummyStore

## 1. Gramática básica

| Concepto | Azure Function | Huawei FunctionGraph |
|----------|---------------|---------------------|
| Entry point | `module.exports = async function (context, req)` | `exports.handler = async (event, context)` |
| Query params | `req.query.get('file')` | `event.queryStringParameters?.file` |
| Body | `req.body` | `event.body` (+ base64 decode si `event.isBase64Encoded`) |
| Logging | `context.log('msg')` | `context.getLogger().info('msg')` |
| Error log | `context.log.error('msg')` | `context.getLogger().error('msg')` |
| HTTP response | `{status, body, headers}` | `{statusCode, headers, body, isBase64Encoded}` |
| Binary response | Return Buffer directamente | Base64 encode + `isBase64Encoded: true` |

## 2. SDKs de Storage

| Servicio | Azure | Huawei OBS |
|----------|-------|------------|
| Import | `@azure/storage-blob` | `@huaweicloud/esdk-obs-browserjs` |
| Client init | `BlobServiceClient.fromConnectionString()` | `new ObsClient({authMode:"iam", server, access_key_id, secret_access_key})` |
| Download | `blobClient.downloadToBuffer()` | `obsClient.getObject({Bucket, Key})` |
| Upload | `blobClient.upload(buffer, size)` | `obsClient.putObject({Bucket, Key, Body})` |
| List | `containerClient.listBlobsFlat()` | `obsClient.listObjects({Bucket})` |

## 3. Trigger configuration

| Azure | Huawei |
|-------|--------|
| `function.json` (bindings array) | `serverless.yml` o consola APIG |
| `httpTrigger` built-in | APIG trigger config |
| `authLevel: anonymous` | `apigw.auth: none` |
| Blob trigger | OBS Event Notification → FG |
| Timer trigger | FunctionGraph timer trigger |

## 4. Variables de entorno

```yaml
# Azure Function (local.settings.json)
AZURE_STORAGE_CONNECTION_STRING: "DefaultEndpointsProtocol=..."

# Huawei FunctionGraph (environment variables en consola)
OBS_SERVER: "https://obs.la-north-2.myhuaweicloud.com"
OBS_BUCKET: "documents"
AKSK_AK: "${ak}"  # Se inyecta automático en FG
AKSK_SK: "${sk}"  # Se inyecta automático en FG
```

## 5. Demo rápido

```bash
# Antes: Azure Function
cd apps/functiongraph-demo/azure-func
func start  # local

# Después: Huawei FunctionGraph
cd apps/functiongraph-demo/huawei-fg
# Probar localmente con FG emulator o subir a la consola
``` 
