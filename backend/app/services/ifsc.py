from typing import Any
from urllib.parse import quote

import httpx

from app.core.exceptions import ValidationException

_IFSC_BASE = "https://ifsc.razorpay.com"
_BANK_NAMES_URL = (
    "https://cdn.jsdelivr.net/gh/razorpay/ifsc@master/src/banknames.json"
)

# Indian state / UT display name → ISO3166-2 (used by Razorpay /places + /search)
_STATE_NAME_TO_ISO: dict[str, str] = {
    "ANDAMAN AND NICOBAR ISLANDS": "IN-AN",
    "ANDHRA PRADESH": "IN-AP",
    "ARUNACHAL PRADESH": "IN-AR",
    "ASSAM": "IN-AS",
    "BIHAR": "IN-BR",
    "CHANDIGARH": "IN-CH",
    "CHHATTISGARH": "IN-CT",
    "DADRA AND NAGAR HAVELI": "IN-DN",
    "DADRA AND NAGAR HAVELI AND DAMAN AND DIU": "IN-DN",
    "DAMAN AND DIU": "IN-DD",
    "DELHI": "IN-DL",
    "GOA": "IN-GA",
    "GUJARAT": "IN-GJ",
    "HARYANA": "IN-HR",
    "HIMACHAL PRADESH": "IN-HP",
    "JAMMU AND KASHMIR": "IN-JK",
    "JHARKHAND": "IN-JH",
    "KARNATAKA": "IN-KA",
    "KERALA": "IN-KL",
    "LADAKH": "IN-LA",
    "LAKSHADWEEP": "IN-LD",
    "MADHYA PRADESH": "IN-MP",
    "MAHARASHTRA": "IN-MH",
    "MANIPUR": "IN-MN",
    "MEGHALAYA": "IN-ML",
    "MIZORAM": "IN-MZ",
    "NAGALAND": "IN-NL",
    "ODISHA": "IN-OR",
    "ORISSA": "IN-OR",
    "PUDUCHERRY": "IN-PY",
    "PUNJAB": "IN-PB",
    "RAJASTHAN": "IN-RJ",
    "SIKKIM": "IN-SK",
    "TAMIL NADU": "IN-TN",
    "TELANGANA": "IN-TG",
    "TRIPURA": "IN-TR",
    "UTTAR PRADESH": "IN-UP",
    "UTTARAKHAND": "IN-UT",
    "WEST BENGAL": "IN-WB",
}

_banks_cache: dict[str, str] | None = None


def _state_iso(state_name: str) -> str:
    key = state_name.strip().upper()
    iso = _STATE_NAME_TO_ISO.get(key)
    if iso:
        return iso
    raise ValidationException(
        f"Unsupported state '{state_name}'. Try another state or enter IFSC manually."
    )


class IfscService:
    """Razorpay public IFSC API (banknames.json + /places + /search)."""

    async def list_banks(self) -> dict[str, str]:
        global _banks_cache
        if _banks_cache is not None:
            return _banks_cache

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(_BANK_NAMES_URL)
        response.raise_for_status()
        try:
            data = response.json()
        except ValueError as exc:
            raise ValidationException("Unable to load bank list.") from exc

        if not isinstance(data, dict):
            raise ValidationException("Unable to load bank list.")

        _banks_cache = {str(code): str(name) for code, name in data.items()}
        return _banks_cache

    async def list_states(self, bank: str) -> list[str]:
        data = await self._places(bankcode=bank)
        states = data.get("states")
        if isinstance(states, list):
            return [str(s) for s in states if str(s).strip()]
        raise ValidationException("Unable to load states for this bank.")

    async def list_districts(self, bank: str, state: str) -> list[str]:
        data = await self._places(
            bankcode=bank,
            state=_state_iso(state),
        )
        districts = data.get("districts")
        if isinstance(districts, list):
            return sorted({str(d) for d in districts if str(d).strip()})
        raise ValidationException("Unable to load districts for this state.")

    async def list_branches(
        self, bank: str, state: str, district: str
    ) -> list[dict[str, str]]:
        state_iso = _state_iso(state)
        place_data = await self._places(
            bankcode=bank,
            state=state_iso,
            district=district,
        )
        branch_names = place_data.get("branches")
        if not isinstance(branch_names, list) or not branch_names:
            return await self._search_branches(bank, state_iso, district)

        search_index = await self._search_branch_index(bank, state_iso, district)
        branches: list[dict[str, str]] = []
        for name in branch_names:
            branch = str(name).strip()
            if not branch:
                continue
            ifsc = search_index.get(branch.upper(), "")
            branches.append({"branch": branch, "ifsc": ifsc})
        if branches and all(not b["ifsc"] for b in branches):
            return await self._search_branches(bank, state_iso, district)
        return [b for b in branches if b["ifsc"]]

    async def lookup_ifsc(self, ifsc: str) -> dict[str, Any]:
        code = ifsc.strip().upper()
        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(f"{_IFSC_BASE}/{code}")
        if response.status_code == 404:
            raise ValidationException("IFSC code not found.")
        response.raise_for_status()
        try:
            data = response.json()
        except ValueError as exc:
            raise ValidationException("Invalid response from IFSC service.") from exc
        if not isinstance(data, dict) or not data.get("IFSC"):
            raise ValidationException("IFSC code not found.")
        return data

    async def _places(self, **params: str) -> dict[str, Any]:
        query = "&".join(
            f"{key}={quote(str(value), safe='')}"
            for key, value in params.items()
            if value
        )
        url = f"{_IFSC_BASE}/places?{query}"
        async with httpx.AsyncClient(timeout=25.0) as client:
            response = await client.get(url)
        if response.status_code == 404:
            raise ValidationException("Bank or branch not found.")
        if response.status_code >= 400:
            raise ValidationException("Unable to load IFSC data for this selection.")
        response.raise_for_status()
        try:
            data = response.json()
        except ValueError as exc:
            raise ValidationException("Invalid response from IFSC service.") from exc
        if not isinstance(data, dict):
            raise ValidationException("Invalid response from IFSC service.")
        return data

    async def _search_branches(
        self, bank: str, state_iso: str, district: str
    ) -> list[dict[str, str]]:
        results: list[dict[str, str]] = []
        seen: set[str] = set()
        offset = 0
        district_key = district.strip().upper()
        while offset < 2000:
            data = await self._search(
                bankcode=bank,
                state=state_iso,
                city=district,
                limit=100,
                offset=offset,
            )
            for item in data.get("data") or []:
                if not isinstance(item, dict):
                    continue
                branch = str(item.get("BRANCH") or "").strip()
                ifsc = str(item.get("IFSC") or "").strip().upper()
                item_district = str(item.get("DISTRICT") or "").strip().upper()
                if (
                    branch
                    and ifsc
                    and ifsc not in seen
                    and (not district_key or district_key in item_district)
                ):
                    seen.add(ifsc)
                    results.append({"branch": branch, "ifsc": ifsc})
            if not data.get("hasNext"):
                break
            offset += 100
        return sorted(results, key=lambda item: item["branch"])

    async def _search_branch_index(
        self, bank: str, state_iso: str, district: str
    ) -> dict[str, str]:
        branches = await self._search_branches(bank, state_iso, district)
        return {item["branch"].upper(): item["ifsc"] for item in branches}

    async def _search(self, **params: str | int) -> dict[str, Any]:
        query = "&".join(
            f"{key}={quote(str(value), safe='')}"
            for key, value in params.items()
            if value is not None and value != ""
        )
        url = f"{_IFSC_BASE}/search?{query}"
        async with httpx.AsyncClient(timeout=25.0) as client:
            response = await client.get(url)
        response.raise_for_status()
        try:
            data = response.json()
        except ValueError as exc:
            raise ValidationException("Invalid response from IFSC service.") from exc
        if not isinstance(data, dict):
            raise ValidationException("Invalid response from IFSC service.")
        return data
