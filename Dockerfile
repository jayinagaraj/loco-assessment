# Stage 1: Builder
FROM python:3.9-slim AS builder

WORKDIR /app

COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

# Stage 2: Runtime
FROM python:3.9-slim

WORKDIR /app

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

# Copy application and dependencies
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY . .

# Expose port
EXPOSE 80

# Run application
CMD ["python", "app.py"]
