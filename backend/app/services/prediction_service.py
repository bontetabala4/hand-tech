"""
Logique métier liée à l'enregistrement des prédictions.

Depuis l'ajout de l'authentification, chaque prédiction est rattachée au
vrai utilisateur connecté (plus d'utilisateur anonyme partagé).
"""

from sqlalchemy.orm import Session

from app.models.db_models import Prediction, RecognitionSession, User


def record_prediction(
    db: Session, user: User, sign: str, confidence: float, mocked: bool
) -> Prediction:
    """Crée une session pour l'utilisateur connecté et y enregistre une prédiction."""
    session = RecognitionSession(user_id=user.id)
    db.add(session)
    db.flush()  # attribue un id sans encore valider la transaction

    prediction = Prediction(
        session_id=session.id, sign=sign, confidence=confidence, mocked=mocked
    )
    db.add(prediction)
    db.commit()
    db.refresh(prediction)
    return prediction


def get_recent_predictions(db: Session, user: User, limit: int = 50) -> list[Prediction]:
    """Retourne les prédictions les plus récentes de l'utilisateur connecté."""
    return (
        db.query(Prediction)
        .join(RecognitionSession, Prediction.session_id == RecognitionSession.id)
        .filter(RecognitionSession.user_id == user.id)
        .order_by(Prediction.created_at.desc())
        .limit(limit)
        .all()
    )
