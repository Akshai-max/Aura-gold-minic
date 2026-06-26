"""Fetch and print live + history metal prices from the running API."""
import asyncio
import sys

import httpx

BASE = "http://localhost:8000/api/v1"
EMAIL = "superadmin@agsgold.com"
PASSWORD = "adminpassword"


async def main() -> None:
    async with httpx.AsyncClient(timeout=60) as client:
        login = await client.post(
            f"{BASE}/auth/login",
            json={"email": EMAIL, "password": PASSWORD},
        )
        if login.status_code != 200:
            print("LOGIN_FAILED", login.status_code, login.text[:300])
            sys.exit(1)

        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        live = await client.get(f"{BASE}/dashboard/metal-prices", headers=headers)
        if live.status_code != 200:
            print("LIVE_FAILED", live.status_code, live.text[:300])
            sys.exit(1)

        data = live.json()
        gold = data["gold"]
        silver = data["silver"]
        print("=== LIVE PRICES ===")
        print(
            f"Gold:   Rs {float(gold['retail_price']):,.2f} / gm"
            f"  (change {float(gold['change_percent']):+.2f}%)"
        )
        print(
            f"Silver: Rs {float(silver['retail_price']):,.2f} / gm"
            f"  (change {float(silver['change_percent']):+.2f}%)"
        )
        print(f"Refreshed: {data['refreshed_at']}")

        for range_key in ("1M", "3M", "6M", "1Y", "3Y"):
            history = await client.get(
                f"{BASE}/dashboard/metal-prices/history",
                headers=headers,
                params={"metal": "gold", "range": range_key},
            )
            if history.status_code != 200:
                print(f"\nHISTORY {range_key} FAILED", history.status_code)
                continue

            hist = history.json()
            points = hist["points"]
            perf = float(hist["performance_percent"])
            print(
                f"\n=== GOLD HISTORY {range_key}"
                f" ({len(points)} points, perf {perf:+.2f}%) ==="
            )
            if not points:
                continue
            print(
                f"  Start: {points[0]['label']}"
                f" -> Rs {float(points[0]['price']):,.2f}"
            )
            print(
                f"  End:   {points[-1]['label']}"
                f" -> Rs {float(points[-1]['price']):,.2f}"
            )
            print("  Recent:")
            for point in points[-5:]:
                print(f"    {point['label']}: Rs {float(point['price']):,.2f}")


if __name__ == "__main__":
    asyncio.run(main())
