import asyncio

from sqlalchemy import text

from app.core.kyc_profile import loads_profile, profile_to_schema
from app.database.session import async_session_maker


async def main() -> None:
    async with async_session_maker() as session:
        result = await session.execute(
            text("SELECT email, kyc_status, kyc_profile FROM users ORDER BY email")
        )
        for email, kyc_status, kyc_profile in result.fetchall():
            if kyc_status == "not_started" and not kyc_profile:
                continue
            print("---", email, kyc_status)
            print("raw:", (kyc_profile or "")[:500])
            try:
                schema = profile_to_schema(loads_profile(kyc_profile))
                print("schema OK:", schema)
            except Exception as exc:
                print("schema FAIL:", exc)


if __name__ == "__main__":
    asyncio.run(main())
