from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class PlatformSetting(Base):
    __tablename__ = "settings"

    id: Mapped[int] = mapped_column(primary_key=True)
    platform_name: Mapped[str] = mapped_column(String(120), default="AGS")
    support_email: Mapped[str] = mapped_column(String(255), default="support@ags.com")
    contact_number: Mapped[str] = mapped_column(String(30), default="+91-0000000000")
    maintenance_mode: Mapped[bool] = mapped_column(Boolean, default=False)
    app_version: Mapped[str] = mapped_column(String(40), default="0.1.0")
