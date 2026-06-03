from sqlalchemy import select

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models.role import Role
from app.models.setting import PlatformSetting
from app.models.user import User

ADMIN_PERMISSIONS = [
    "user.create",
    "user.read",
    "user.update",
    "user.delete",
    "role.manage",
    "settings.manage",
    "audit.read",
    "dashboard.read",
    "profile.manage",
]
SHAREHOLDER_PERMISSIONS = ["report.read", "analytics.read", "dashboard.read", "profile.manage"]
USER_PERMISSIONS = ["dashboard.read", "profile.manage"]


def seed() -> None:
    db = SessionLocal()
    try:
        roles = {
            "ADMIN": ADMIN_PERMISSIONS,
            "SHAREHOLDER": SHAREHOLDER_PERMISSIONS,
            "USER": USER_PERMISSIONS,
        }
        for name, permissions in roles.items():
            role = db.scalar(select(Role).where(Role.name == name))
            if role is None:
                db.add(Role(name=name, permissions=permissions))
            else:
                role.permissions = permissions
        db.flush()

        admin_role = db.scalar(select(Role).where(Role.name == "ADMIN"))
        admin = db.scalar(select(User).where(User.email == "admin@auragold.com"))
        if admin is None:
            db.add(
                User(
                    first_name="Admin",
                    last_name="User",
                    email="admin@auragold.com",
                    mobile_number="+910000000000",
                    hashed_password=hash_password("Admin@123"),
                    role=admin_role,
                    email_verified=True,
                )
            )

        shareholder_role = db.scalar(select(Role).where(Role.name == "SHAREHOLDER"))
        shareholder = db.scalar(select(User).where(User.email == "shareholder@auragold.com"))
        if shareholder is None:
            db.add(
                User(
                    first_name="Shareholder",
                    last_name="User",
                    email="shareholder@auragold.com",
                    mobile_number="+919876543210",
                    hashed_password=hash_password("Shareholder@123"),
                    role=shareholder_role,
                    email_verified=True,
                )
            )

        user_role = db.scalar(select(Role).where(Role.name == "USER"))
        user = db.scalar(select(User).where(User.email == "user@auragold.com"))
        if user is None:
            db.add(
                User(
                    first_name="Regular",
                    last_name="User",
                    email="user@auragold.com",
                    mobile_number="+919123456789",
                    hashed_password=hash_password("User@123"),
                    role=user_role,
                    email_verified=True,
                )
            )
        if db.scalar(select(PlatformSetting)) is None:
            db.add(PlatformSetting())
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    seed()

