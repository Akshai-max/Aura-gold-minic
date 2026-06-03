# Aura Gold

Production-ready Flutter and FastAPI foundation for Aura Gold.

This phase implements authentication, user management, RBAC, dashboards, settings, audit logging, networking, local storage, theming, and backend platform APIs. Gold Trading, SIP, Staking, Wallet, Portfolio, Alerts, Redemption, and related business modules are intentionally not implemented yet.

## Structure

- `lib/` Flutter mobile application using Clean Architecture-friendly feature modules.
- `backend/` FastAPI service using SQLAlchemy, Alembic, JWT auth, Redis-ready settings, RBAC, and seed data.

## Flutter

```powershell
flutter pub get
flutter test
flutter run
```

## Backend

Install Python 3.12+, PostgreSQL, and Redis, then:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e .[dev]
alembic upgrade head
python -m app.seed
uvicorn app.main:app --reload
```

Default admin:

- Email: `admin@auragold.com`
- Password: `Admin@123`

