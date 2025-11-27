# Tate Embeddings Service

A standalone FastAPI microservice for computing text and image embeddings using OpenCLIP, enabling cross-modal artwork search for the Tate art gallery website.

> **Note:** For the original feature requirements and acceptance criteria, see [TICKET.md](TICKET.md)

## Overview

This service provides REST API endpoints to generate 512-dimensional embeddings from text queries and images. It uses OpenCLIP's `ViT-B-32` model with `laion2b_s34b_b79k` pretrained weights to enable semantic search where users can find artworks using natural language queries like "landscape painting".

## What This Service Does

- **Text Embeddings:** Convert text queries into 512-dim vectors for semantic search
- **Image Embeddings:** Convert image URLs into 512-dim vectors that share the same embedding space as text
- **Cross-Modal Search:** Enables finding images using text queries (text ↔ image in same vector space)
- **Authentication:** Bearer token-based authentication for secure API access
- **Production-Ready:** Containerized with Gunicorn workers for concurrent request handling

## Architecture

### Technology Stack

- **FastAPI** - Modern async web framework with auto-documentation
- **Gunicorn + Uvicorn** - Production ASGI server
- **PyTorch + OpenCLIP** - Multi-modal embedding model
- **Pillow** - Image processing
- **httpx** - Async HTTP client for downloading images

### Model Configuration

- **Default Model:** `ViT-B-32` with `laion2b_s34b_b79k` weights
- **Embedding Dimension:** 512
- **Memory Requirements:** ~2GB RAM minimum
- **Alternatives:** `ViT-L-14` for higher quality (768 dims) but slower

## Local Development

### Prerequisites

- Python 3.11+
- Poetry
- Docker (optional)

### Quick Start with Makefile

The easiest way to run the service locally is using the Makefile with Docker:

```bash
# Start the service (builds Docker image, installs dependencies, runs on port 8002)
make run
```

That's it! The service will build, install dependencies via Poetry, and start in Docker on http://localhost:8002.

**Other useful commands:**

```bash
make help            # Show all available commands
make logs            # View container logs
make stop            # Stop the container
make restart         # Restart the container
make test            # Run tests (in Poetry)
make test-coverage   # Run tests with coverage report
make run-local       # Run directly with Poetry (no Docker)
make clean           # Clean up cache files
make destroy         # DESTROY EVERYTHING (container, image, cache)
```

**Customize with environment variables:**

```bash
# Use different auth token
AUTH_TOKEN=my_custom_token make run

# Use different port
PORT=9000 make run

# Use different model
MODEL_NAME=ViT-L-14 PRETRAINED=laion2b_s34b_b79k make run
```

**Note:** `make run` uses Docker by default. If you prefer to run directly with Poetry (no Docker), use `make run-local` instead.

### Manual Setup (Alternative)

If you prefer not to use the Makefile:

1. Install dependencies:

   ```bash
   poetry install
   ```

2. Set environment variables:

   ```bash
   export AUTH_TOKEN="local_dev_token_123"
   export MODEL_NAME="ViT-B-32"
   export PRETRAINED="laion2b_s34b_b79k"
   ```

3. Run the service:

   ```bash
   poetry run uvicorn app.main:app --reload --port 8002
   ```

4. Access interactive API docs at: http://localhost:8002/docs

### Docker Commands

**Using Makefile (recommended):**

```bash
make run             # Build and run (one command does everything!)
make stop            # Stop and remove the container
make restart         # Restart the container
make logs            # View live logs
make build           # Just build the image (without running)
```

**Manual Docker commands:**

```bash
# Build
docker build -t tate-embeddings .

# Run
docker run -d --name tate-embeddings-container \
  -p 8002:8000 \
  -e AUTH_TOKEN="your_token" \
  -e MODEL_NAME="ViT-B-32" \
  -e PRETRAINED="laion2b_s34b_b79k" \
  tate-embeddings

# View logs
docker logs -f tate-embeddings-container

# Stop
docker stop tate-embeddings-container
docker rm tate-embeddings-container
```

Note: The container internally uses port 8000, but we map it to 8002 on the host to avoid conflicts with the main Tate website.

### Integration with tate-wagtail

To use this service with the main Tate website locally:

1. Clone this repo as a sibling to `tate-wagtail`:

   ```bash
   cd /path/to/projects
   git clone git@github.com:TateMedia/tate-wagtail.git
   git clone git@github.com:TateMedia/tate-embeddings.git
   ```

2. In `tate-wagtail/docker-compose.yml`, uncomment the `embedding-service` section

3. Start both services:

   ```bash
   cd tate-wagtail
   docker-compose up web embedding-service
   ```

4. The embedding service will be available at: `http://localhost:8002`

## Quick Start: Making Your First Request

### Step 1: Start the Service

Start the service with one command:

```bash
make run
```

This builds the Docker image, installs dependencies, and starts the service on `http://localhost:8002`.

Wait for startup to complete (~30 seconds first time as the model loads):

```
INFO:     Application startup complete.
✓ Container started: tate-embeddings-container
```

### Step 2: Test with Postman (Recommended)

The easiest way to test the API is with our pre-configured Postman collection!

#### Import the Collection

1. **Open Postman** and click **Import** (top left)
2. **Drag and drop** `Tate-Embeddings.postman_collection.json` from this repository
3. **Click the collection** name to expand it

#### What's Included

- ✅ Health check endpoint
- ✅ Text embedding endpoint
- ✅ Image embedding endpoint
- ✅ 5 example art queries (styles, subjects, moods)
- ✅ Authentication test cases
- ✅ Pre-configured auth token and URL

#### Start Testing

1. **Expand** any folder in the collection
2. **Click** a request (try "Embed Text" → "Impressionist painting of water lilies")
3. **Click Send**
4. **View response** - you'll get a 512-dimensional embedding vector!

The collection is pre-configured with:
- `base_url`: `http://localhost:8002`
- `auth_token`: `local_dev_token_123`

**Change these** in Collection → Variables if needed.

### Alternative: Test with curl

#### Health Check

```bash
curl http://localhost:8002/
```

**Response:**

```json
{ "status": "ok", "service": "tate-embeddings" }
```

#### Text Embedding Example

```bash
curl -X POST http://localhost:8002/embed-text \
  -H "Authorization: Bearer local_dev_token_123" \
  -H "Content-Type: application/json" \
  -d '{"query": "impressionist painting of water lilies"}'
```

**Response:**

```json
{
  "embedding": [
    0.023456789,
    -0.012345678,
    0.045678901,
    ...
    (512 numbers total)
  ]
}
```

#### Image Embedding Example

```bash
curl -X POST http://localhost:8002/embed-image \
  -H "Authorization: Bearer local_dev_token_123" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.tate.org.uk/static/images/default.jpg"}'
```

**Response:**

```json
{
  "embedding": [
    0.034567890,
    -0.023456789,
    0.056789012,
    ...
    (512 numbers total)
  ]
}
```

### Alternative: Interactive API Docs

FastAPI provides automatic interactive documentation at **http://localhost:8002/docs**:

1. Click **Authorize** and enter token: `local_dev_token_123`
2. Expand any endpoint and click **Try it out**
3. Enter your request data and click **Execute**

## Testing

All tests run inside Docker to ensure consistency with the production environment.

**Using Makefile:**

```bash
make test              # Run all tests in Docker
make test-coverage     # Run tests with coverage in Docker
```

The tests will run in the same Docker container as the production service, ensuring environment parity.

## API Documentation

### Authentication

All endpoints require Bearer token authentication:

```bash
Authorization: Bearer YOUR_TOKEN_HERE
```

### Endpoints

#### GET /

Health check endpoint.

**Response:**

```json
{
  "status": "ok",
  "service": "tate-embeddings"
}
```

#### POST /embed-text

Generate embedding for text query.

**Request:**

```json
{
  "query": "landscape painting"
}
```

**Response:**

```json
{
  "embedding": [0.123, -0.456, 0.789, ...]
}
```

**Example:**

```bash
curl -X POST http://localhost:8002/embed-text \
  -H "Authorization: Bearer local_dev_token_123" \
  -H "Content-Type: application/json" \
  -d '{"query": "landscape painting"}'
```

#### POST /embed-image

Generate embedding for image URL.

**Request:**

```json
{
  "url": "https://www.tate.org.uk/static/images/default.jpg"
}
```

**Response:**

```json
{
  "embedding": [0.123, -0.456, 0.789, ...]
}
```

**Example:**

```bash
curl -X POST http://localhost:8002/embed-image \
  -H "Authorization: Bearer local_dev_token_123" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.tate.org.uk/static/images/default.jpg"}'
```

## Deployment

### Railway Deployment

1. Connect this repository to Railway
2. Set environment variables:
   - `AUTH_TOKEN` - Generate a secure token
   - `MODEL_NAME` - `ViT-B-32`
   - `PRETRAINED` - `laion2b_s34b_b79k`
3. Railway will automatically detect the Dockerfile and deploy

### Environment Variables

| Variable     | Description                     | Default             | Required               |
| ------------ | ------------------------------- | ------------------- | ---------------------- |
| `AUTH_TOKEN` | Bearer token for authentication | -                   | Yes                    |
| `MODEL_NAME` | OpenCLIP model name             | `ViT-B-32`          | No                     |
| `PRETRAINED` | Model pretrained weights        | `laion2b_s34b_b79k` | No                     |
| `PORT`       | Server port                     | `8000`              | No (Railway sets this) |

## Project Structure

```
tate-embeddings/
├── app/
│   ├── __init__.py                          # Package init
│   ├── main.py                              # FastAPI app & endpoints
│   ├── models.py                            # Pydantic request/response models
│   ├── embeddings.py                        # OpenCLIP embedding logic
│   ├── auth.py                              # Bearer token authentication
│   └── config.py                            # Settings configuration
├── tests/
│   ├── __init__.py
│   ├── test_endpoints.py                    # Endpoint tests
│   └── test_auth.py                         # Authentication tests
├── .env.example                             # Example environment variables
├── .dockerignore
├── .gitignore
├── Dockerfile                               # Production container
├── Makefile                                 # Development commands
├── Tate-Embeddings.postman_collection.json  # Postman API collection
├── TICKET.md                                # Original feature requirements
├── AI_CONTEXT.md                            # Development context notes
├── pyproject.toml                           # Poetry dependencies
├── poetry.lock
└── README.md
```

## Performance Notes

- **Model download:** ~350MB on first startup (cached afterwards)
- **Inference time:**
  - Text: ~50-100ms (CPU)
  - Image: ~200-500ms (CPU, includes download)
- **Memory:** ~2GB per worker
- **Concurrency:** 4 gunicorn workers recommended
- **GPU:** Optional but recommended for production (5-10x faster)

## Troubleshooting

### Model download fails

The model downloads automatically on first startup. If it fails:

```bash
# Pre-download the model
poetry run python -c "import open_clip; open_clip.create_model_and_transforms('ViT-B-32', pretrained='laion2b_s34b_b79k')"
```

### Out of memory

Reduce the number of workers or use a smaller model:

```bash
export MODEL_NAME="ViT-B-32"  # Default, ~2GB per worker
# Or use even smaller:
export MODEL_NAME="ViT-B-16"  # ~1GB per worker
```

### Slow image processing

- Ensure images are accessible and not too large
- Consider adding a CDN or caching layer
- Use GPU for faster inference

### Complete reset

If you want to completely destroy and rebuild everything:

```bash
make destroy    # Remove container, image, and all cache
make run        # Rebuild and start fresh
```

## License

Copyright © 2025 Tate. All rights reserved.
