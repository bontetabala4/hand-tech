"""Point d'entrée public de traduction textuelle compatible Flutter."""

import logging

from fastapi import APIRouter, HTTPException, status

from app.schemas.translation_api import (
    TextTranslationRequest,
    TextTranslationResponse,
)
from app.services.libretranslate import (
    TranslationProviderUnavailable,
    translate_text,
)

logger = logging.getLogger(__name__)
router = APIRouter(tags=["text translation"])


@router.post("/translate", response_model=TextTranslationResponse)
async def translate(payload: TextTranslationRequest) -> TextTranslationResponse:
    try:
        result = await translate_text(
            text=payload.q,
            source=payload.source,
            target=payload.target,
        )
    except TranslationProviderUnavailable:
        logger.warning("Le fournisseur de traduction est indisponible.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Le service de traduction est temporairement indisponible.",
        ) from None

    return TextTranslationResponse(translatedText=result)
