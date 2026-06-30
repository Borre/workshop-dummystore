// Azure Function (original) — HTTP trigger, reads blob, logs
// ==========================================
// File: function.json
// {
//   "bindings": [
//     {
//       "authLevel": "anonymous",
//       "type": "httpTrigger",
//       "direction": "in",
//       "name": "req",
//       "methods": ["get", "post"]
//     },
//     {
//       "type": "http",
//       "direction": "out",
//       "name": "res"
//     }
//   ]
// }

const { BlobServiceClient } = require("@azure/storage-blob");

module.exports = async function (context, req) {
    context.log("Processing request...");

    const file = req.query.file || (req.body && req.body.file);
    if (!file) {
        context.res = {
            status: 400,
            body: { error: "Missing 'file' parameter" }
        };
        return;
    }

    try {
        const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
        const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
        const containerClient = blobServiceClient.getContainerClient("documents");
        const blobClient = containerClient.getBlockBlobClient(file);

        const buffer = await blobClient.downloadToBuffer();
        
        context.res = {
            status: 200,
            headers: { "Content-Type": "application/octet-stream" },
            body: buffer
        };
    } catch (err) {
        context.log.error(`Error: ${err.message}`);
        context.res = {
            status: 500,
            body: { error: err.message }
        };
    }
};
