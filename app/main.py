"""FastAPI application for generating text and image embeddings."""

import logging
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException

from . import embeddings
from .auth import verify_token
from .config import settings
from .embeddings import EmbeddingModel
from .models import EmbeddingResponse, ImageEmbedRequest, TextEmbedRequest

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifecycle manager for the FastAPI app.

    Loads the embedding model on startup and keeps it in memory
    for the duration of the application.
    """
    # Startup: Load model
    logger.info(f"Loading model: {settings.model_name} ({settings.pretrained})")

    embeddings.embedding_model = EmbeddingModel(
        settings.model_name, settings.pretrained
    )

    logger.info("Model loaded successfully - ready to accept requests")
    yield

    # Shutdown: cleanup if needed
    logger.info("Shutting down")


app = FastAPI(
    title="Tate Embeddings Service",
    description="Compute text and image embeddings for artwork search using OpenCLIP",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/")
async def root():
    """
    Health check endpoint.

    Returns:
        Status information about the service
    """
    return {
        "status": "ok",
        "service": "tate-embeddings",
        "model": settings.model_name,
        "pretrained": settings.pretrained,
    }


@app.post("/embed-text", response_model=EmbeddingResponse)
async def embed_text(request: TextEmbedRequest, token: str = Depends(verify_token)):
    """
    Generate embedding for text query.

    This endpoint converts text into a vector embedding that can be compared
    with image embeddings for cross-modal search.

    Args:
        request: Text embedding request with query string
        token: Authentication token (injected by dependency)

    Returns:
        EmbeddingResponse with the embedding vector

    Raises:
        HTTPException: If embedding generation fails
    """
    try:
        logger.info(f"Generating text embedding for query: {request.query[:50]}...")
        embedding = await embeddings.embedding_model.embed_text(request.query)
        logger.info(f"Generated embedding with {len(embedding)} dimensions")
        return EmbeddingResponse(embedding=embedding)
    except Exception as e:
        logger.error(f"Error embedding text: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/embed-image", response_model=EmbeddingResponse)
async def embed_image(request: ImageEmbedRequest, token: str = Depends(verify_token)):
    """
    Generate embedding for image from URL.

    This endpoint downloads an image from the provided URL and converts it
    into a vector embedding that can be compared with text embeddings.

    Args:
        request: Image embedding request with image URL
        token: Authentication token (injected by dependency)

    Returns:
        EmbeddingResponse with the embedding vector

    Raises:
        HTTPException: If image download or embedding generation fails
    """
    try:
        logger.info(f"Generating image embedding for URL: {request.url}")
        embedding = await embeddings.embedding_model.embed_image(str(request.url))
        logger.info(f"Generated embedding with {len(embedding)} dimensions")
        return EmbeddingResponse(embedding=embedding)
    except Exception as e:
        logger.error(f"Error embedding image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
