FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend/ .

# Copy Flutter web build as static files
COPY frontend/gat_mentor/build/web/ ./static/

# Copy seed data
COPY backend/seeds/ ./seeds/

# Railway sets PORT dynamically — use shell form so $PORT is expanded at runtime
CMD gunicorn app.main:app -w 2 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:${PORT:-8000} --timeout 120
