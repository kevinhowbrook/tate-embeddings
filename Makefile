.PHONY: help install run run-local test test-coverage clean build stop restart logs lint format check-model destroy

# Default target - show help
help:
	@echo "Tate Embeddings Service - Makefile Commands"
	@echo ""
	@echo "Quick Start:"
	@echo "  make run          Build and start the service in Docker (port 8002)"
	@echo "  make stop         Stop the Docker container"
	@echo "  make restart      Restart the Docker container"
	@echo "  make logs         View container logs"
	@echo ""
	@echo "Setup:"
	@echo "  make build        Build Docker image"
	@echo "  make install      Install dependencies with Poetry (for local dev)"
	@echo "  make check-model  Pre-download the OpenCLIP model (~350MB)"
	@echo ""
	@echo "Development:"
	@echo "  make run-local    Run directly with Poetry (no Docker)"
	@echo "  make test         Run tests in Docker"
	@echo "  make test-coverage Run tests with coverage in Docker"
	@echo "  make lint         Run linters (ruff, mypy)"
	@echo "  make format       Format code with ruff"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean        Remove cache files and artifacts"
	@echo "  make destroy      DESTROY EVERYTHING (container, image, cache)"
	@echo ""
	@echo "Environment Variables:"
	@echo "  AUTH_TOKEN       Auth token (default: local_dev_token_123)"
	@echo "  MODEL_NAME       OpenCLIP model (default: ViT-B-32)"
	@echo "  PRETRAINED       Pretrained weights (default: laion2b_s34b_b79k)"
	@echo "  PORT             Service port (default: 8002)"

# Variables with defaults
AUTH_TOKEN ?= local_dev_token_123
MODEL_NAME ?= ViT-B-32
PRETRAINED ?= laion2b_s34b_b79k
PORT ?= 8002
DOCKER_IMAGE ?= tate-embeddings
DOCKER_CONTAINER ?= tate-embeddings-container

# Install dependencies (for local development without Docker)
install:
	@echo "Installing dependencies with Poetry..."
	poetry install
	@echo "✓ Dependencies installed"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Run 'make check-model' to pre-download the model (optional)"
	@echo "  2. Run 'make run' to start the service in Docker"
	@echo "  3. Or run 'make run-local' to run directly with Poetry"

# Pre-download the model (optional but recommended for first run)
check-model:
	@echo "Pre-downloading OpenCLIP model (this may take a few minutes)..."
	@AUTH_TOKEN=$(AUTH_TOKEN) \
	MODEL_NAME=$(MODEL_NAME) \
	PRETRAINED=$(PRETRAINED) \
	poetry run python -c "import open_clip; open_clip.create_model_and_transforms('$(MODEL_NAME)', pretrained='$(PRETRAINED)'); print('✓ Model downloaded successfully')"

# Build and run the service in Docker (default)
run: stop build
	@echo "Starting Tate Embeddings Service in Docker..."
	@echo "Service will be available at: http://localhost:$(PORT)"
	@echo "API docs at: http://localhost:$(PORT)/docs"
	@echo "Auth token: $(AUTH_TOKEN)"
	@echo ""
	docker run -d \
		--name $(DOCKER_CONTAINER) \
		-p $(PORT):8000 \
		-e AUTH_TOKEN=$(AUTH_TOKEN) \
		-e MODEL_NAME=$(MODEL_NAME) \
		-e PRETRAINED=$(PRETRAINED) \
		$(DOCKER_IMAGE)
	@echo "✓ Container started: $(DOCKER_CONTAINER)"
	@echo ""
	@echo "View logs with: make logs"
	@echo "Stop with: make stop"

# Run the service directly with Poetry (no Docker)
run-local:
	@echo "Starting Tate Embeddings Service with Poetry..."
	@echo "Service will be available at: http://localhost:$(PORT)"
	@echo "API docs at: http://localhost:$(PORT)/docs"
	@echo "Auth token: $(AUTH_TOKEN)"
	@echo ""
	@AUTH_TOKEN=$(AUTH_TOKEN) \
	MODEL_NAME=$(MODEL_NAME) \
	PRETRAINED=$(PRETRAINED) \
	poetry run uvicorn app.main:app --reload --port $(PORT)

# Run tests in Docker
test:
	@echo "Running tests in Docker..."
	docker run --rm \
		-e AUTH_TOKEN=$(AUTH_TOKEN) \
		-e MODEL_NAME=$(MODEL_NAME) \
		-e PRETRAINED=$(PRETRAINED) \
		$(DOCKER_IMAGE) \
		pytest -v
	@echo "✓ Tests completed"

# Run tests with coverage in Docker
test-coverage:
	@echo "Running tests with coverage in Docker..."
	docker run --rm \
		-v $(PWD)/htmlcov:/app/htmlcov \
		-e AUTH_TOKEN=$(AUTH_TOKEN) \
		-e MODEL_NAME=$(MODEL_NAME) \
		-e PRETRAINED=$(PRETRAINED) \
		$(DOCKER_IMAGE) \
		sh -c "pytest --cov=app --cov-report=html --cov-report=term"
	@echo ""
	@echo "✓ Coverage report generated in htmlcov/index.html"

# Lint code
lint:
	@echo "Running linters..."
	@poetry run ruff check app tests || true
	@echo "✓ Linting complete"

# Format code
format:
	@echo "Formatting code..."
	@poetry run ruff format app tests
	@poetry run ruff check --fix app tests || true
	@echo "✓ Code formatted"

# Build Docker image
build:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE) .
	@echo "✓ Docker image built: $(DOCKER_IMAGE)"

# Stop Docker container
stop:
	@echo "Stopping Docker container..."
	@docker stop $(DOCKER_CONTAINER) 2>/dev/null || true
	@docker rm $(DOCKER_CONTAINER) 2>/dev/null || true
	@echo "✓ Container stopped"

# Restart the Docker container
restart: stop run
	@echo "✓ Container restarted"

# View logs from the Docker container
logs:
	@echo "Showing logs for $(DOCKER_CONTAINER)..."
	@echo "Press Ctrl+C to exit"
	@docker logs -f $(DOCKER_CONTAINER)

# Clean up cache and build artifacts
clean:
	@echo "Cleaning up..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	rm -rf htmlcov .coverage 2>/dev/null || true
	@echo "✓ Cleanup complete"

# Destroy everything - container, image, cache, the lot!
destroy: stop
	@echo "⚠️  DESTROYING EVERYTHING..."
	@echo ""
	@echo "Removing Docker image..."
	@docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	@echo "Removing dangling images..."
	@docker image prune -f 2>/dev/null || true
	@echo "Cleaning up cache and artifacts..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@rm -rf htmlcov .coverage 2>/dev/null || true
	@rm -rf .venv 2>/dev/null || true
	@echo ""
	@echo "💥 DESTRUCTION COMPLETE!"
	@echo "Removed:"
	@echo "  - Docker container ($(DOCKER_CONTAINER))"
	@echo "  - Docker image ($(DOCKER_IMAGE))"
	@echo "  - Python cache files"
	@echo "  - Test artifacts"
	@echo "  - Virtual environment"
	@echo ""
	@echo "To rebuild: make run"

