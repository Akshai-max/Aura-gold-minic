from fastapi import APIRouter

from app.api.v1 import (
    audit,
    auth,
    gold_price,
    permissions,
    portfolio,
    roles,
    settings,
    transactions,
    users,
    wallet,
    buy,
    sell,
    orders,
    payments,
    trades,
    trading_settings,
)

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(roles.router, prefix="/roles", tags=["roles"])
api_router.include_router(permissions.router, prefix="/permissions", tags=["permissions"])
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])
api_router.include_router(audit.router, prefix="/audit", tags=["audit"])
api_router.include_router(gold_price.router, prefix="/gold-price", tags=["gold-price"])
api_router.include_router(wallet.router, prefix="/wallet", tags=["wallet"])
api_router.include_router(portfolio.router, prefix="/portfolio", tags=["portfolio"])
api_router.include_router(transactions.router, prefix="/transactions", tags=["transactions"])
api_router.include_router(buy.router, prefix="/buy", tags=["buy"])
api_router.include_router(sell.router, prefix="/sell", tags=["sell"])
api_router.include_router(orders.router, prefix="/orders", tags=["orders"])
api_router.include_router(payments.router, prefix="/payments", tags=["payments"])
api_router.include_router(trades.router, prefix="/trades", tags=["trades"])
api_router.include_router(trading_settings.router, prefix="/trading-settings", tags=["trading-settings"])
