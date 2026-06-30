// Huawei FunctionGraph (target) — same logic, adapted syntax
// ==========================================
// APIG trigger configured via serverless.yml or console
//
// Key differences from Azure Function:
// 1. Export is fixed: exports.handler = async (event, context)
// 2. HTTP params from event.queryStringParameters
// 3. Log via context.getLogger().info()
// 4. OBS client instead of BlobServiceClient
// 5. Binary response needs base64 + isBase64Encoded flag

const ObsClient = require("@huaweicloud/esdk-obs-browserjs");

const obsClient = new ObsClient({
    authMode: "iam",
    server: process.env.OBS_SERVER || "https://obs.la-north-2.myhuaweicloud.com",
    access_key_id: process.env.AKSK_AK,
    secret_access_key: process.env.AKSK_SK,
});

exports.handler = async (event, context) => {
    const logger = context.getLogger();
    logger.info("Processing request...");

    // 1. Get parameters — different from Azure
    const query = event.queryStringParameters || {};
    const body = event.body ? JSON.parse(event.isBase64Encoded
        ? Buffer.from(event.body, "base64").toString()
        : event.body) : {};
    const file = query.file || body.file;

    if (!file) {
        return {
            statusCode: 400,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ error: "Missing 'file' parameter" }),
            isBase64Encoded: false,
        };
    }

    try {
        // 2. Download from OBS — different SDK, same S3-compatible API
        const bucket = process.env.OBS_BUCKET || "documents";
        const result = await new Promise((resolve, reject) => {
            obsClient.getObject({
                Bucket: bucket,
                Key: file,
            }, (err, data) => {
                if (err) reject(err);
                else resolve(data);
            });
        });

        // 3. Binary response — must encode to base64 + set flag
        const base64Content = Buffer.from(result.Body).toString("base64");

        return {
            statusCode: 200,
            headers: { "Content-Type": "application/octet-stream" },
            body: base64Content,
            isBase64Encoded: true,
        };
    } catch (err) {
        logger.error(`Error: ${err.message}`);
        return {
            statusCode: 500,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ error: err.message }),
            isBase64Encoded: false,
        };
    }
};
