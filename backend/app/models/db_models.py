"""
Modèles ORM (tables SQL réelles), à ne pas confondre avec app/models/prediction.py
qui contient les schémas Pydantic de l'API (formats des requêtes/réponses HTTP).

Trois tables, comme prévu section 14 du cahier des charges :
- users     : personnes utilisant l'application
- sessions  : une session de reconnaissance (ex: une utilisation de l'appli)
- predictions : chaque signe reconnu pendant une session, avec son score
"""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    display_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    sessions: Mapped[list["RecognitionSession"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class RecognitionSession(Base):
    """Une session = une période d'utilisation de la reconnaissance par un utilisateur."""

    __tablename__ = "sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user: Mapped["User"] = relationship(back_populates="sessions")
    predictions: Mapped[list["Prediction"]] = relationship(
        back_populates="session", cascade="all, delete-orphan"
    )


class Prediction(Base):
    """Un signe reconnu à un instant donné, dans une session."""

    __tablename__ = "predictions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    session_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("sessions.id", ondelete="CASCADE"), nullable=False
    )
    sign: Mapped[str] = mapped_column(String(100), nullable=False)
    confidence: Mapped[float] = mapped_column(Float, nullable=False)
    mocked: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    session: Mapped["RecognitionSession"] = relationship(back_populates="predictions")
