"""Hit live KYC endpoints against the dev database to reproduce 500s."""
import asyncio
import uuid

from httpx import ASGITransport, AsyncClient
from sqlalchemy import text

from app.core.security import create_access_token
from app.database.session import async_session_maker
from app.main import app


async def main() -> None:
    async with async_session_maker() as session:
        result = await session.execute(
            text("SELECT id, email FROM users WHERE email = 'piranavmn.2006@gmail.com'")
        )
        row = result.first()
        if not row:
            print("User not found")
            return
        user_id, email = row
        print("Testing as", email, user_id)

    token = create_access_token(subject=uuid.UUID(str(user_id)))
    headers = {"Authorization": f"Bearer {token}"}

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        for path in (
            "/api/v1/profile/kyc/status",
            "/api/v1/dashboard/personal",
            "/api/v1/dashboard/metal-prices",
        ):
            response = await client.get(path, headers=headers)
            print(path, response.status_code)
            print(response.text[:500])


if __name__ == "__main__":
    asyncio.run(main())
