FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (for psycopg2 and any ML packages)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for better caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Create uploads directory
RUN mkdir -p /app/uploads

# Environment variables (these will be overridden by Render)
#ENV DATABASE_URL=postgresql+psycopg2://tradingjournal:changeme@postgres:5432/tradingjournal \
#  UPLOAD_DIR=/app/uploads

# Expose port
EXPOSE 8000

# Run the FastAPI app
# Change "main:app" to match your file structure (e.g., "app.main:app" if your main file is in app/ folder)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]