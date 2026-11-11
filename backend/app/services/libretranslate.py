"""Client HTTP du service LibreTranslate."""

import httpx

from app.core.config import settings


class TranslationProviderUnavailable(Exception):
    """Le fournisseur de traduction ne répond pas correctement."""


async def translate_text(*, text: str, source: str, target: str) -> str:
    endpoint = settings.libretranslate_url
    if not endpoint:
        raise TranslationProviderUnavailable("Fournisseur non configuré.")

    payload: dict[str, str] = {
        "q": text,
        "source": source,
        "target": target,
        "format": "text",
    }
    if settings.libretranslate_api_key:
        payload["api_key"] = settings.libretranslate_api_key

    try:
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(settings.translation_timeout_seconds)
        ) as client:
            response = await client.post(
                f"{endpoint.rstrip('/')}/translate",
                json=payload,
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            data = response.json()
    except (httpx.HTTPError, ValueError) as exc:
        raise TranslationProviderUnavailable from exc

    translated = data.get("translatedText") if isinstance(data, dict) else None
    if not isinstance(translated, str) or not translated.strip():
        raise TranslationProviderUnavailable("Réponse fournisseur invalide.")

    return translated.strip()
