"""
Logique métier liée à l'enregistrement des prédictions.

Pour le MVP, il n'y a pas encore d'authentification (section 19 : "lorsque
nécessaire" — pas encore le cas). On rattache donc chaque prédiction à un
utilisateur anonyme unique, créé automatiquement au premier appel.

TODO: une fois l'authentification en place, remplacer l'utilisateur anonyme
par le véritable utilisateur connecté, et réutiliser une session existante
plutôt que d'en recréer une à chaque appel.
"""

from sqlalchemy.orm import Session

from app.models.db_models import Prediction, RecognitionSession, User

_ANONYMOUS_EMAIL = "anonyme@handtech.local"


def _get_or_create_anonymous_user(db: Session) -> User:
    user = db.query(User).filter(User.email == _ANONYMOUS_EMAIL).first()
    if user is None:
        user = User(email=_ANONYMOUS_EMAIL, display_name="Utilisateur anonyme (MVP)")
        db.add(user)
        db.flush()  # attribue un id sans encore valider la transaction
    return user


def record_prediction(db: Session, sign: str, confidence: float, mocked: bool) -> Prediction:
    """Crée une session et y enregistre une prédiction, de façon atomique."""
    user = _get_or_create_anonymous_user(db)

    session = RecognitionSession(user_id=user.id)
    db.add(session)
    db.flush()

    prediction = Prediction(
        session_id=session.id, sign=sign, confidence=confidence, mocked=mocked
    )
    db.add(prediction)
    db.commit()
    db.refresh(prediction)
    return prediction


def get_recent_predictions(db: Session, limit: int = 50) -> list[Prediction]:
    """
    Retourne les prédictions les plus récentes, toutes sessions confondues.

    TODO: une fois l'authentification en place, filtrer par utilisateur
    connecté plutôt que de renvoyer l'historique global (MVP mono-utilisateur
    anonyme pour l'instant).
    """
    return (
        db.query(Prediction)
        .order_by(Prediction.created_at.desc())
        .limit(limit)
        .all()
    )
