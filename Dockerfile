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

# Copy project files
COPY . .

# Create required folders with correct permissions
RUN mkdir -p /app/burgir/static /app/burgir/staticfiles /app/burgir/media && \
    touch /app/burgir/db.sqlite3 && \
    chmod -R u+rwX /app

# OpenShift-compatible CMD
CMD sh -c "
    python manage.py migrate --no-input && \
    python manage.py collectstatic --no-input && \
    exec gunicorn burgir.wsgi:application \
        --bind 0.0.0.0:\$PORT \
        --workers 4 \
        --timeout 120 \
        --keep-alive 120 \
        --access-logfile - \
        --error-logfile -
"
