from fastapi import APIRouter, Depends

from app.api.v1.deps import CurrentUser, DbSession, require_role
from app.models.user import User
from app.schemas.gold import PlatformPortfolioRead, PortfolioRead
from app.services.gold_service import platform_portfolio_read, portfolio_read

router = APIRouter()


@router.get("", response_model=PortfolioRead)
def get_portfolio(db: DbSession, user: CurrentUser, range: str | None = None) -> PortfolioRead:
    return portfolio_read(db, user.id, range)


@router.get("/platform-overview", response_model=PlatformPortfolioRead)
def get_platform_portfolio_overview(
    db: DbSession,
    _: User = Depends(require_role("ADMIN", "SHAREHOLDER")),
) -> PlatformPortfolioRead:
    return platform_portfolio_read(db)
