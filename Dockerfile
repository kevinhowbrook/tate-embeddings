# Use Python 3.10 base image to match pyproject.toml requirements
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install NumPy 1.x first (PyTorch requires NumPy <2)
RUN pip install --no-cache-dir "numpy<2"

# Install PyTorch CPU-only (smaller and no CUDA dependencies)
RUN pip install --no-cache-dir \
    torch==2.1.0+cpu \
    torchvision==0.16.0+cpu \
    --index-url https://download.pytorch.org/whl/cpu

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    ln -s /root/.local/bin/poetry /usr/local/bin/poetry

# Copy dependency files
COPY pyproject.toml poetry.lock* ./

# Configure Poetry to not use virtualenv and install ALL dependencies (including dev for testing)
# Increase timeout and add retry logic for large PyTorch downloads
# --no-root: Don't install the project itself yet (we'll copy the code later)
RUN poetry config virtualenvs.create false && \
    poetry config installer.max-workers 10 && \
    poetry install --no-root --no-interaction --no-ansi || \
    (sleep 5 && poetry install --no-root --no-interaction --no-ansi) || \
    (sleep 10 && poetry install --no-root --no-interaction --no-ansi)

# Copy application code and tests
COPY app/ ./app/
COPY tests/ ./tests/

# Pre-download the OpenCLIP model to cache it in the image (~350MB)
# This makes first startup and tests much faster
RUN python -c "import open_clip; model, _, _ = open_clip.create_model_and_transforms('ViT-B-32', pretrained='laion2b_s34b_b79k'); print('✓ Model cached in image')"

# Expose port
EXPOSE 8000

# Run with gunicorn + uvicorn workers
# Port is configurable via $PORT environment variable (Railway sets this)
CMD gunicorn app.main:app \
    --workers 4 \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:${PORT:-8000} \
    --timeout 120 \
    --log-level info \
    --access-logfile - \
    --error-logfile -

