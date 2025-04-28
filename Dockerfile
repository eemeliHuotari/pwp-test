FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PORT 8080
ENV DJANGO_SETTINGS_MODULE=burgir.settings

# Create and set work directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Prepare directories (must use numeric permissions)
RUN mkdir -p /app/burgir/static && \
    touch /app/burgir/db.sqlite3 && \
    chmod -R 777 /app  # Temporary wide permissions

# OpenShift-compatible run instructions
CMD ["sh", "-c", "
    # Apply runtime permissions (handles random UID)
    chmod -R u+rwX /app && \
    chmod 666 /app/burgir/db.sqlite3 || true && \
    # Run migrations if needed
    python manage.py migrate --no-input && \
    # Start Gunicorn
    exec gunicorn burgir.wsgi:application \
        --bind 0.0.0.0:$PORT \
        --workers 4 \
        --timeout 120 \
        --keep-alive 120 \
        --access-logfile - \
        --error-logfile -
"]
