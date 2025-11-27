.PHONY: help run test test-coverage clean build stop restart logs destroy

# Default target - show help
help:
	@echo "Tate Embeddings Service - Docker Commands"
	@echo ""
	@echo "Quick Start:"
	@echo "  make run          Build and start the service (port 8002)"
	@echo "  make logs         View container logs"
	@echo "  make stop         Stop the container"
	@echo "  make restart      Restart the container"
	@echo ""
	@echo "Development:"
	@echo "  make test         Run all tests in Docker"
	@echo "  make test-coverage Run tests with coverage in Docker"
	@echo "  make build        Build Docker image only"
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

# Build and run the service in Docker
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

