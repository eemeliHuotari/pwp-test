# Use official Python image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PORT 8080  # Rahti typically uses port 8080

# Set work directory
WORKDIR /app

# Install system dependencies (if needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy project
COPY . .


RUN if [ -f burgir/settings.py ] && grep -q "STATIC_ROOT" burgir/settings.py; then \
        python manage.py collectstatic --noinput; \
    fi

# Run Gunicorn
CMD gunicorn burgir.wsgi:application --bind 0.0.0.0:$PORT --workers 2
