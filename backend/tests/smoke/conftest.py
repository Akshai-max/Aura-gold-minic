import os

import httpx
import pytest

SMOKE_BASE_URL = os.getenv("SMOKE_BASE_URL", "http://localhost:8000").rstrip("/")


def _smoke_enabled() -> bool:
    return os.getenv("RUN_SMOKE_TESTS", "false").lower() in ("1", "true", "yes")


def pytest_collection_modifyitems(config, items):
    """Skip smoke tests unless RUN_SMOKE_TESTS is explicitly enabled."""
    if _smoke_enabled():
        return
    skip_marker = pytest.mark.skip(
        reason="Set RUN_SMOKE_TESTS=true to run deployment smoke tests"
    )
    for item in items:
        if "smoke" in item.keywords:
            item.add_marker(skip_marker)


@pytest.fixture
def smoke_client():
    if not _smoke_enabled():
        pytest.skip("Set RUN_SMOKE_TESTS=true to run deployment smoke tests")

    try:
        with httpx.Client(base_url=SMOKE_BASE_URL, timeout=5.0) as probe:
            probe.get("/health")
    except httpx.ConnectError:
        pytest.skip(
            f"Smoke target unavailable at {SMOKE_BASE_URL}. "
            "Start the API server or set SMOKE_BASE_URL."
        )

    client = httpx.Client(base_url=SMOKE_BASE_URL, timeout=15.0)
    yield client
    client.close()
