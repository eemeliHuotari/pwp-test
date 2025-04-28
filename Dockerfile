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

# Install dependencies first for better layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Create a non-root user and switch to it
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Database and static files setup
RUN mkdir -p /app/burgir/static && \
    chmod 664 /burgir/db.sqlite3 && \
    chmod 775 /burgir

# Run migrations and collectstatic (optional - might be better in entrypoint.sh)
# RUN python manage.py migrate --no-input && \
#     python manage.py collectstatic --no-input

# Run Gunicorn with production settings
CMD gunicorn burgir.wsgi:application \
    --bind 0.0.0.0:$PORT \
    --workers 4 \
    --timeout 120 \
    --keep-alive 120 \
    --access-logfile - \
    --error-logfile -
