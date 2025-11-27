# AI Context Notes - Tate Embeddings Service

## Quick Summary

This is a **standalone FastAPI microservice** that computes text and image embeddings using OpenCLIP for the Tate art gallery website. It enables **cross-modal text-to-image search** - users can search for artworks using natural language queries like "landscape painting" and find visually similar images.

## Architecture Overview

### The Big Picture

```
User Query → Django/Wagtail → Elasticsearch KNN Search → Artwork Results
                ↑                      ↑
                |                      |
           Text Embedding      Image Embeddings
                |                      |
                └──────────────────────┘
                         ↓
                  THIS SERVICE
              (tate-embeddings)
```

### How It Works

1. **Nightly Process (Django management command):**

   - Iterate through artworks with `null` `image_vector` field
   - Get image URL from Azure Blob Storage
   - Call `/embed-image` on this service
   - Store 512-dim embedding in `ArtworkPage.image_vector` field
   - Update Elasticsearch dense vector index

2. **Search Time (User query):**
   - User enters text query: "landscape painting"
   - Django calls `/embed-text` on this service
   - Get 512-dim text embedding
   - Perform KNN search in Elasticsearch against image embeddings
   - Return matching artwork pages

### Why Separate Service?

- **Heavy ML dependencies** (PyTorch, OpenCLIP) - don't want in Django
- **Independent scaling** - can deploy with GPU on Railway
- **Model stays in memory** - faster inference than loading per request
- **Technology isolation** - FastAPI + async better for this than Django

## Key Technology Decisions

### Model: OpenCLIP ViT-B-32

- **Why CLIP?** Designed for cross-modal search (text ↔ image)
- **Why ViT-B-32?** Good balance of speed/quality/size
- **Embedding dimension:** 512 (smaller than ViT-L-14's 768)
- **Pretrained weights:** `laion2b_s34b_b79k` (open, high quality)
- **Alternative considered:** ViT-L-14 (better quality, slower, 768 dims)

### FastAPI vs Flask

- **Auto-documentation** at `/docs` (Swagger UI)
- **Request validation** via Pydantic
- **Better async** for I/O (downloading images)
- **Type safety** with Python type hints
- **Modern** and well-maintained

### Poetry vs requirements.txt

- Better dependency resolution
- Lock file for reproducible builds
- Cleaner project structure

## Repository Structure

### Separate Repository (Not Monorepo)

- **This repo:** `tate-embeddings` (standalone microservice)
- **Main repo:** `tate-wagtail` (Django/Wagtail website)
- **Why separate?** Different concerns, independent deployment, ticket says "standalone"

### Local Development Integration

```bash
/projects/
  ├── tate-wagtail/
  │   └── docker-compose.yml  # References ../tate-embeddings
  └── tate-embeddings/        # This repo
      └── Dockerfile
```

Developers who need vector search features clone both repos as siblings.

## Implementation Status

### ✅ Completed

- [x] Project structure created
- [x] Poetry configuration with all dependencies
- [x] FastAPI app with lifespan management
- [x] Bearer token authentication
- [x] `/embed-text` endpoint with validation
- [x] `/embed-image` endpoint with validation
- [x] OpenCLIP model loading and inference
- [x] Comprehensive test suite (endpoints + auth)
- [x] Dockerfile with gunicorn + uvicorn workers
- [x] Railway deployment configuration
- [x] Makefile for easy Docker-based development
- [x] Postman collection for API testing
- [x] Documentation (README, TICKET.md, AI_CONTEXT.md)

### 🔄 Next Steps (Future Tickets)

1. Test the service locally
2. Deploy to Railway
3. Integrate with `tate-wagtail`:
   - Add `image_vector` field to `ArtworkPage` model
   - Create `tate/vector_search` Django app
   - Implement `update_embeddings` management command
   - Add Elasticsearch dense vector configuration
   - Implement search utilities (`search_embeddings`)
4. Build search UI

## Important Context

### This is Cross-Modal Search, Not Image-to-Image

- **User input:** Text ("landscape painting")
- **Stored data:** Image embeddings
- **Magic:** CLIP maps both to same vector space
- **Result:** Text query finds visually similar images

This is sometimes called:

- ✅ Text-to-image search
- ✅ Cross-modal search
- ✅ Semantic image search
- ❌ NOT image-to-image search (reverse image search)
- ❌ NOT just "image vector search" (ambiguous term)

### The Main App Works Without This

The `tate-wagtail` Django app has **graceful degradation**:

- Tests use mocks (don't need actual service)
- Core features work without vector search
- Optional feature for experimental search
- Environment variable `EMBEDDINGS_SERVICE_URL` enables it

### Model Downloads on First Startup

- OpenCLIP downloads ~350MB model weights on first run
- Cached in `~/.cache/` after first download
- Consider pre-downloading in production Docker image for faster startup

## Configuration

### Environment Variables

```bash
# Required
AUTH_TOKEN=secret_token_here

# Optional (defaults shown)
MODEL_NAME=ViT-B-32
PRETRAINED=laion2b_s34b_b79k
WORKERS=4
PORT=8000  # Railway sets this automatically
```

### Authentication

- **Method:** Bearer token in `Authorization` header
- **Token:** Shared secret between Django app and this service
- **Format:** `Authorization: Bearer YOUR_TOKEN`
- **Security:** Generate strong random token for production

## Testing Strategy

### Running Tests

```bash
poetry run pytest                          # Run all tests
poetry run pytest -v                       # Verbose
poetry run pytest --cov=app                # With coverage
poetry run pytest tests/test_endpoints.py  # Specific file
```

### Test Coverage

- ✅ Text embedding endpoint (success case)
- ✅ Image embedding endpoint (success case with real URL)
- ✅ Authentication (valid, invalid, missing tokens)
- ✅ Input validation (empty queries, malformed URLs)
- ✅ Error handling (invalid image URLs, network errors)
- ✅ Health check endpoint

### Test Image URL

Uses actual Tate website image: `https://www.tate.org.uk/static/images/default.jpg`

## Performance Characteristics

### Inference Times (CPU)

- **Text embedding:** ~50-100ms
- **Image embedding:** ~200-500ms (includes download)
- **With GPU:** 5-10x faster

### Memory Requirements

- **Per worker:** ~2GB RAM
- **4 workers:** ~8GB total recommended
- **Startup:** ~350MB model download (first time only)

### Concurrency

- **4 gunicorn workers** (configurable)
- **Async I/O** for image downloads
- **Timeout:** 120 seconds for long-running requests

## Deployment

### Railway

1. Connect repository to Railway
2. Railway auto-detects Dockerfile
3. Set environment variables (AUTH_TOKEN, etc.)
4. Deploy
5. Railway provides public URL

### Docker Locally

```bash
docker build -t tate-embeddings .
docker run -p 8002:8000 \
  -e AUTH_TOKEN=dev_token \
  -e MODEL_NAME=ViT-B-32 \
  -e PRETRAINED=laion2b_s34b_b79k \
  tate-embeddings
```

Note: Maps container port 8000 to host port 8002 to avoid conflicts with main Tate site.

### Development with Makefile (Recommended)

```bash
make run              # Build and run in Docker (one command!)
make logs             # View logs
make stop             # Stop container
make restart          # Restart container
make run-local        # Run directly with Poetry (no Docker)
```

### Development (Manual - No Docker)

```bash
poetry install
export AUTH_TOKEN=dev_token_123
poetry run uvicorn app.main:app --reload --port 8002
```

Note: Use port 8002 to avoid conflicts with main Tate website on port 8000.

## Future Enhancements (Not in Current Scope)

### Possible Future Features

1. **Image-to-image search:** Upload image → find similar artworks
2. **Batch embedding endpoint:** Process multiple items at once
3. **Caching layer:** Redis cache for frequently embedded queries
4. **Model hot-swapping:** Switch models without restart
5. **Multiple model support:** Let caller choose model
6. **GPU optimization:** CUDA-specific optimizations
7. **Monitoring:** Prometheus metrics, request tracing
8. **Rate limiting:** Prevent abuse

### Alternative Models to Consider

- **ViT-L-14:** Higher quality, 768 dims, slower
- **ViT-H-14:** Highest quality, 1024 dims, slowest
- **ConvNeXT:** Different architecture, competitive quality
- **BLIP-2:** More recent, potentially better text understanding

## Common Issues & Solutions

### "Model download timeout"

- Pre-download model: `poetry run python -c "import open_clip; open_clip.create_model_and_transforms('ViT-B-32', pretrained='laion2b_s34b_b79k')"`
- Or increase timeout in Dockerfile

### "Out of memory"

- Reduce workers: `--workers 2`
- Use smaller model: `MODEL_NAME=ViT-B-16`
- Add more RAM to deployment

### "Image download fails"

- Check image URL is publicly accessible
- Check firewall/network restrictions
- Verify image format is supported (JPEG, PNG, etc.)

### "Tests fail on first run"

- Model needs to download first (~350MB)
- Subsequent runs will be faster (cached)

## Related Documentation

- **Main project architecture:** See diagram in `tate-wagtail` repo
- **Ticket:** TSE-108 (included in README.md)
- **OpenCLIP docs:** https://github.com/mlfoundations/open_clip
- **FastAPI docs:** https://fastapi.tiangolo.com
- **Elasticsearch dense vectors:** https://www.elastic.co/guide/en/elasticsearch/reference/current/dense-vector.html

## Questions to Ask If Context Is Unclear

1. Which ticket are we working on? (This service implements TSE-108)
2. Are we implementing the microservice or the Django integration? (This is the microservice)
3. Is this for local dev or production? (Works for both)
4. What model should we use? (Default: ViT-B-32, can be changed via env var)
5. Do we need GPU support? (Optional, works on CPU)

## Debug Commands

```bash
# Check service health
curl http://localhost:8002/

# Test text embedding
curl -X POST http://localhost:8002/embed-text \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "test"}'

# Test image embedding
curl -X POST http://localhost:8002/embed-image \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.tate.org.uk/static/images/default.jpg"}'

# Check model loading
poetry run python -c "from app.embeddings import EmbeddingModel; m = EmbeddingModel('ViT-B-32', 'laion2b_s34b_b79k'); print('OK')"

# Run specific test
poetry run pytest tests/test_endpoints.py::test_embed_text_success -v
```

---

**Last Updated:** 2025-11-27
**Status:** Initial implementation complete, ready for testing
**Current Ticket:** TSE-108 - Compute embeddings outside web app
