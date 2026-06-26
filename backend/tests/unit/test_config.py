from app.core.config import normalize_database_url


def test_normalize_database_url_railway_postgres():
    url = "postgresql://user:pass@host.railway.internal:5432/railway"
    assert normalize_database_url(url) == (
        "postgresql+asyncpg://user:pass@host.railway.internal:5432/railway"
    )


def test_normalize_database_url_postgres_scheme():
    url = "postgres://user:pass@localhost/db"
    assert normalize_database_url(url) == (
        "postgresql+asyncpg://user:pass@localhost/db"
    )


def test_normalize_database_url_already_async():
    url = "postgresql+asyncpg://user:pass@localhost/db"
    assert normalize_database_url(url) == url
