from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, Index
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDPrimaryKeyMixin, TimestampMixin


class SignupOtpChallenge(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "signup_otp_challenges"

    mobile_number: Mapped[str] = mapped_column(String(15), nullable=False)
    otp_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    consumed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    __table_args__ = (
        Index("ix_signup_otp_mobile_created", "mobile_number", "created_at"),
    )
