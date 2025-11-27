"""Pydantic models for request and response validation."""

from typing import List

from pydantic import BaseModel, Field, HttpUrl


class TextEmbedRequest(BaseModel):
    """Request model for text embedding endpoint."""

    query: str = Field(..., min_length=1, max_length=5000, description="Text to embed")

    model_config = {
        "json_schema_extra": {"examples": [{"query": "landscape painting"}]}
    }


class ImageEmbedRequest(BaseModel):
    """Request model for image embedding endpoint."""

    url: HttpUrl = Field(..., description="URL of the image to embed")

    model_config = {
        "json_schema_extra": {
            "examples": [{"url": "https://www.tate.org.uk/static/images/default.jpg"}]
        }
    }


class EmbeddingResponse(BaseModel):
    """Response model for embedding endpoints."""

    embedding: list[float] = Field(
        ..., description="Vector embedding as a list of floats"
    )

    model_config = {
        "json_schema_extra": {"examples": [{"embedding": [0.123, -0.456, 0.789]}]}
    }
