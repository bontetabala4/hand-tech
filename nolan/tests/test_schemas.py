from app.schemas import GlossPrediction, RecognitionResponse


def test_recognition_response_accepts_a_gloss() -> None:
    response = RecognitionResponse(
        model_version="0.1.0",
        glosses=[GlossPrediction(label="BONJOUR", confidence=0.95, start=0.0, end=1.2)],
    )
    assert response.glosses[0].label == "BONJOUR"
    assert response.glosses[0].confidence == 0.95
