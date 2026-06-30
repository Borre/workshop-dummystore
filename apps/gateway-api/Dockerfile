FROM python:3.12-slim

RUN apt-get update -qq && apt-get install -y -qq curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

EXPOSE 9000

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,json; r=urllib.request.urlopen('http://localhost:9000/health'); status=json.loads(r.read()); exit(0) if status.get('status')=='ok' else exit(1)"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9000"]
