# ===== MULTI-STAGE BUILD FOR GOOGLE CLOUD RUN =====
# Stage 1: Build dependencies
FROM python:3.12.7-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# ===== Stage 2: Runtime image =====
FROM python:3.12.7-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy application code
COPY app.py .
COPY .env* ./

# Create models directory
RUN mkdir -p /app/models

# Copy YOLO models if they exist locally (optional - will auto-download if missing)
COPY yolov8n.pt yolov8n-pose.pt /app/ 2>/dev/null || true

# Environment variables for Cloud Run
ENV PORT=8080 \
    PYTHONUNBUFFERED=1 \
    CUDA_VISIBLE_DEVICES=-1 \
    TF_CPP_MIN_LOG_LEVEL=3

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT}/api/health || exit 1

# Non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser

# Expose port (Cloud Run will override with $PORT)
EXPOSE 8080

# Start command
CMD exec uvicorn app:app --host 0.0.0.0 --port ${PORT} --workers 1
