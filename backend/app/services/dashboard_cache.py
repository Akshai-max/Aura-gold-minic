from app.schemas.dashboard import PersonalDashboardResponse

_personal_cache: dict[str, tuple[float, PersonalDashboardResponse]] = {}


def get_personal_dashboard_cache() -> dict[str, tuple[float, PersonalDashboardResponse]]:
    return _personal_cache


def clear_personal_dashboard_cache(user_id: str | None = None) -> None:
    """Drop cached dashboard payloads so gold/scheme changes show immediately."""
    if user_id is None:
        _personal_cache.clear()
        return
    _personal_cache.pop(user_id, None)
