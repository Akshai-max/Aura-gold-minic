"""Normalize stored KYC profile JSON (e.g. numeric pincode -> string)."""
import asyncio

from sqlalchemy import text

from app.core.kyc_profile import dumps_profile, loads_profile
from app.database.session import async_session_maker


async def main() -> None:
    async with async_session_maker() as session:
        result = await session.execute(
            text("SELECT id, email, kyc_profile FROM users WHERE kyc_profile IS NOT NULL")
        )
        updated = 0
        for user_id, email, kyc_profile in result.fetchall():
            raw = loads_profile(kyc_profile)
            if not raw:
                continue
            fixed = dumps_profile(raw)
            if fixed != kyc_profile:
                await session.execute(
                    text("UPDATE users SET kyc_profile = :profile WHERE id = :id"),
                    {"profile": fixed, "id": user_id},
                )
                updated += 1
                print("fixed", email)
        await session.commit()
        print(f"Done. Updated {updated} profile(s).")


if __name__ == "__main__":
    asyncio.run(main())
