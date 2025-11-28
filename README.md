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

- Docker
- Make (usually pre-installed on Linux/Mac)

### Using the Makefile

Run the service with one command:

```bash
make run
```

This builds the Docker image, installs dependencies, and starts the service on `http://localhost:8002`.

**All available commands:**

```bash
make run             # Build and start the service
make logs            # View container logs
make stop            # Stop the container
make restart         # Restart the container
make test            # Run all tests
make test-coverage   # Run tests with coverage report
make clean           # Remove cache files
make destroy         # Destroy everything (container, image, cache)
```

**Customize with environment variables:**

```bash
AUTH_TOKEN=my_token make run          # Use different auth token
PORT=9000 make run                     # Use different port
MODEL_NAME=ViT-L-14 make run          # Use different model
```

**Note:** The container internally uses port 8000, but maps to 8002 on your host to avoid conflicts with the main Tate website.

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

All tests run in Docker to ensure consistency with production:

```bash
make test              # Run all tests
make test-coverage     # Run tests with coverage report
```

**Results:** 13/13 tests passing in ~3 seconds

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

## Railway Deployment

### How Railway Deployment Works

Railway is a Platform-as-a-Service (PaaS) that automatically builds and deploys your Docker containers. Here's how it works for this app:

#### 1. **Repository Connection**
   - Connect your GitHub repository to Railway
   - Railway monitors the `main` branch for changes
   - Every push to `main` triggers an automatic deployment

#### 2. **Automatic Build Process**
   Railway reads `railway.json` and follows these steps:
   
   a. **Detects Dockerfile** - Railway sees the `Dockerfile` in the repo root
   
   b. **Builds Docker Image:**
      - Runs `docker build` using your Dockerfile
      - Installs Python 3.10
      - Installs NumPy 1.x
      - Installs PyTorch CPU-only (~185MB)
      - Installs Poetry
      - Runs `poetry install` to install all dependencies
      - Copies your app code
   
   c. **Creates Container:**
      - Creates a container from the built image
      - Injects environment variables you configured
      - Sets the `$PORT` variable (Railway chooses this dynamically)

#### 3. **Runtime Execution**
   Railway runs the CMD from your Dockerfile:
   
   ```bash
   gunicorn app.main:app \
     --workers 4 \
     --worker-class uvicorn.workers.UvicornWorker \
     --bind 0.0.0.0:$PORT \
     --timeout 120
   ```
   
   This starts:
   - **4 Gunicorn worker processes** (for handling multiple requests concurrently)
   - Each worker runs **Uvicorn** (ASGI server for FastAPI)
   - Listens on `0.0.0.0:$PORT` (Railway assigns the port)
   - **120-second timeout** (needed for slow model loading)

#### 4. **First Startup** (~30-60 seconds)
   When the container starts for the first time:
   
   - Each of the 4 workers loads the OpenCLIP model
   - Model downloads from HuggingFace (~350MB)
   - Model gets cached in container filesystem
   - Workers signal "ready to accept requests"
   - Railway marks the service as "healthy"

#### 5. **Subsequent Requests**
   - Model is in memory (no re-download needed)
   - Text embeddings: ~50-100ms
   - Image embeddings: ~200-500ms

#### 6. **Public URL**
   - Railway provides a public URL: `https://your-app.railway.app`
   - Use this URL in your Django/Wagtail app
   - Set `EMBEDDINGS_SERVICE_URL` in Django to point to Railway URL

### Railway Setup Steps

1. **Create Railway Account**
   - Go to [railway.app](https://railway.app)
   - Sign in with GitHub

2. **Create New Project**
   - Click **"New Project"**
   - Select **"Deploy from GitHub repo"**
   - Choose `tate-embeddings` repository
   - Railway auto-detects the Dockerfile

3. **Configure Environment Variables**
   - Go to **Variables** tab in Railway dashboard
   - Add these required variables:
   
   | Variable | Value | Notes |
   |----------|-------|-------|
   | `AUTH_TOKEN` | `<generate-secure-token>` | Generate with: `openssl rand -hex 32` |
   | `MODEL_NAME` | `ViT-B-32` | Optional, this is the default |
   | `PRETRAINED` | `laion2b_s34b_b79k` | Optional, this is the default |
   
   **⚠️ Important:** Railway automatically sets `PORT` - don't set this yourself!

4. **Deploy**
   - Click **"Deploy"**
   - Railway builds the Docker image (takes ~5-10 minutes first time)
   - Watch build logs in the Railway dashboard
   - Once deployed, Railway provides your public URL

5. **Get Your Service URL**
   - Go to **Settings** → **Domains**
   - Copy the Railway-provided domain: `https://tate-embeddings-production.up.railway.app`
   - Use this URL in your Django app

### Testing Your Railway Deployment

Update your Postman collection:

1. Open Postman
2. Click collection → **Variables**
3. Update `base_url` to your Railway URL:
   - Change: `http://localhost:8002`
   - To: `https://your-app.railway.app`
4. Update `auth_token` to your production token
5. Click **Send** on any request

Or test with curl:

```bash
curl https://your-app.railway.app/
# Should return: {"status":"ok","service":"tate-embeddings"}

curl -X POST https://your-app.railway.app/embed-text \
  -H "Authorization: Bearer YOUR_PRODUCTION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "landscape painting"}'
```

### Railway vs Local Development

| Aspect | Local (Docker) | Railway (Production) |
|--------|----------------|----------------------|
| **Build** | `make build` | Automatic on git push |
| **Run** | `make run` | Automatic after build |
| **Port** | 8002 (you choose) | Dynamic (Railway sets) |
| **URL** | http://localhost:8002 | https://your-app.railway.app |
| **Auth Token** | `local_dev_token_123` | Production token (secure) |
| **Logs** | `make logs` | Railway dashboard |
| **Restart** | `make restart` | Railway dashboard or API |
| **Environment** | Set in Makefile | Set in Railway dashboard |

### Monitoring Your Deployment

In the Railway dashboard you can:
- **View logs** - See real-time application logs
- **Check metrics** - CPU, memory, network usage
- **View deployments** - History of all deployments
- **Restart service** - If needed
- **Scale resources** - Upgrade RAM/CPU if needed

### Cost Considerations

Railway charges based on:
- **Compute time** (vCPU hours)
- **Memory usage** (~8GB for 4 workers)
- **Network egress** (outbound traffic)

For this service:
- Expect ~$15-30/month for moderate usage
- Model is CPU-only (no GPU needed = cheaper)
- 4 workers @ ~2GB each = ~8GB RAM needed

### Integration with Django/Wagtail

Once deployed, configure your Django app:

```python
# settings.py
EMBEDDINGS_SERVICE_URL = "https://your-app.railway.app"
EMBEDDINGS_AUTH_TOKEN = env("EMBEDDINGS_AUTH_TOKEN")  # Store in .env

# In your code:
import httpx

async def get_text_embedding(query: str):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.EMBEDDINGS_SERVICE_URL}/embed-text",
            json={"query": query},
            headers={"Authorization": f"Bearer {settings.EMBEDDINGS_AUTH_TOKEN}"},
        )
        return response.json()["embedding"]
```

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
WORKERS=2 make run              # Use fewer workers
MODEL_NAME=ViT-B-16 make run    # Use smaller model (~1GB per worker)
```

### Slow image processing

- Ensure images are accessible and not too large
- Consider adding a CDN or caching layer
- Use GPU for faster inference

### Complete reset

Completely destroy and rebuild everything:

```bash
make destroy    # Remove container, image, cache
make run        # Rebuild and start fresh
```

## License

Copyright © 2025 Tate. All rights reserved.
