"""Embedding generation using OpenCLIP models."""

import logging
from io import BytesIO
from typing import List

import httpx
import open_clip
import torch
from PIL import Image

logger = logging.getLogger(__name__)


class EmbeddingModel:
    """
    OpenCLIP model wrapper for generating text and image embeddings.

    The model is loaded once on initialization and kept in memory for fast inference.
    """

    def __init__(self, model_name: str, pretrained: str):
        """
        Initialize the embedding model.

        Args:
            model_name: Name of the OpenCLIP model (e.g., 'ViT-B-32')
            pretrained: Pretrained weights to use (e.g., 'laion2b_s34b_b79k')
        """
        logger.info(f"Loading OpenCLIP model: {model_name} ({pretrained})")

        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Using device: {self.device}")

        # Load model and preprocessing
        self.model, _, self.preprocess = open_clip.create_model_and_transforms(
            model_name, pretrained=pretrained
        )
        self.model.to(self.device)
        self.model.eval()

        # Load tokenizer for text
        self.tokenizer = open_clip.get_tokenizer(model_name)

        logger.info("Model loaded successfully")

    async def embed_text(self, text: str) -> list[float]:
        """
        Generate embedding for text query.

        Args:
            text: Text string to embed

        Returns:
            Normalized embedding vector as a list of floats
        """
        with torch.no_grad():
            # Tokenize text
            text_tokens = self.tokenizer([text]).to(self.device)

            # Generate embedding
            text_features = self.model.encode_text(text_tokens)

            # Normalize to unit vector
            text_features /= text_features.norm(dim=-1, keepdim=True)

            # Convert to list
            return text_features.cpu().numpy()[0].tolist()

    async def embed_image(self, image_url: str) -> list[float]:
        """
        Generate embedding for image from URL.

        Args:
            image_url: URL of the image to embed

        Returns:
            Normalized embedding vector as a list of floats

        Raises:
            httpx.HTTPError: If image download fails
            PIL.UnidentifiedImageError: If image cannot be opened
        """
        # Download image
        async with httpx.AsyncClient() as client:
            response = await client.get(image_url, timeout=30.0)
            response.raise_for_status()
            image_data = response.content

        # Open and preprocess image
        image = Image.open(BytesIO(image_data)).convert("RGB")

        with torch.no_grad():
            # Preprocess image
            image_tensor = self.preprocess(image).unsqueeze(0).to(self.device)

            # Generate embedding
            image_features = self.model.encode_image(image_tensor)

            # Normalize to unit vector
            image_features /= image_features.norm(dim=-1, keepdim=True)

            # Convert to list
            return image_features.cpu().numpy()[0].tolist()


# Global model instance (loaded on startup)
embedding_model: EmbeddingModel = None
