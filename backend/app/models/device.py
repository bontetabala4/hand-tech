import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Device(Base):
    __tablename__ = "devices"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False)
    serial_number: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    type: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="OFFLINE", nullable=False)
    battery_level: Mapped[int | None] = mapped_column(Integer)
    firmware_version: Mapped[str | None] = mapped_column(String(50))
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    organization = relationship("Organization", back_populates="devices")
