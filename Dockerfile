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
 
 # Set work directory
 WORKDIR /app
 
 # Install dependencies
 COPY requirements.txt .
 RUN pip install --upgrade pip && pip install -r requirements.txt
 
 # Copy project
 COPY . .
 
 
 RUN if [ -f burgir/settings.py ] && grep -q "STATIC_ROOT" burgir/settings.py; then \
         python manage.py collectstatic --noinput; \
     fi
 
 # Run Gunicorn
 CMD sh -c "
     mkdir -p /app/burgir/static /app/burgir/media && \
     chmod -R u+rwX /app/burgir && \
     if [ ! -f /app/burgir/db.sqlite3 ]; then
         echo 'No database found, running migrations...'
         python manage.py migrate --no-input
     fi && \
     exec gunicorn burgir.wsgi:application --bind 0.0.0.0:$PORT --workers 4
 "
