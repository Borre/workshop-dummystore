# ---------------------------------------------------------------------------
# Stage 1 — builder
# ---------------------------------------------------------------------------
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

COPY app/ ./app/

# ---------------------------------------------------------------------------
# Stage 2 — runtime
# ---------------------------------------------------------------------------
FROM python:3.12-slim

# Create non-root user
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 --gid 1001 app

WORKDIR /app

COPY --from=builder /root/.local /root/.local
COPY --from=builder /build/app ./app

ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1

EXPOSE 9000

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,json; r=urllib.request.urlopen('http://localhost:9000/health'); status=json.loads(r.read()); exit(0) if status.get('status')=='ok' else exit(1)"

USER app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9000"]
