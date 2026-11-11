"""Tests du contrat de traduction consommé par Flutter."""

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.api.v1 import translate as translate_api
from app.services.libretranslate import TranslationProviderUnavailable

client = TestClient(app)


@pytest.mark.parametrize(
    ("payload", "expected"),
    [
        (
            {"q": "Bonjour", "source": "fr", "target": "en", "format": "text"},
            {"translatedText": "Hello"},
        ),
    ],
)
def test_translate_returns_flutter_contract(monkeypatch, payload, expected):
    async def fake_translate_text(*, text, source, target):
        assert (text, source, target) == ("Bonjour", "fr", "en")
        return "Hello"

    monkeypatch.setattr(translate_api, "translate_text", fake_translate_text)
    response = client.post("/translate", json=payload)

    assert response.status_code == 200
    assert response.json() == expected


def test_translate_rejects_unsupported_language():
    response = client.post(
        "/translate",
        json={"q": "Bonjour", "source": "fr", "target": "xx", "format": "text"},
    )
    assert response.status_code == 422


def test_translate_rejects_text_over_limit():
    response = client.post(
        "/translate",
        json={"q": "x" * 5001, "source": "fr", "target": "en", "format": "text"},
    )
    assert response.status_code == 422


def test_translate_rejects_empty_text():
    response = client.post(
        "/translate",
        json={"q": " ", "source": "fr", "target": "en", "format": "text"},
    )
    assert response.status_code == 422


def test_translate_returns_safe_error_when_provider_is_unavailable(monkeypatch):
    async def unavailable(*, text, source, target):
        raise TranslationProviderUnavailable

    monkeypatch.setattr(translate_api, "translate_text", unavailable)
    response = client.post(
        "/translate",
        json={"q": "Bonjour", "source": "fr", "target": "en", "format": "text"},
    )

    assert response.status_code == 503
    assert response.json() == {
        "detail": "Le service de traduction est temporairement indisponible."
    }
