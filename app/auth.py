"""Authentication middleware using Bearer tokens."""

from fastapi import HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .config import settings

security = HTTPBearer()


async def verify_token(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> str:
    """
    Verify the bearer token matches the configured auth token.

    Args:
        credentials: HTTP authorization credentials from the request

    Returns:
        The validated token string

    Raises:
        HTTPException: If the token is invalid (403 Forbidden)
    """
    if credentials.credentials != settings.auth_token:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid authentication credentials",
        )
    return credentials.credentials
