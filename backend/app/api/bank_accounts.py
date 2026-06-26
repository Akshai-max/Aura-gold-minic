from fastapi import APIRouter, Depends, status

from app.api.dependencies import get_bank_account_service, get_current_user, get_ifsc_service
from app.models.user import User
from app.schemas.bank_account import (
    BankAccountResponse,
    BankLinkInitiateRequest,
    BankLinkInitiateResponse,
    BankLinkVerifyRequest,
    IfscLookupResponse,
)
from app.services.bank_account import BankAccountService
from app.services.ifsc import IfscService

router = APIRouter()


@router.get(
    "",
    response_model=list[BankAccountResponse],
    summary="List linked bank accounts",
)
async def list_bank_accounts(
    current_user: User = Depends(get_current_user),
    service: BankAccountService = Depends(get_bank_account_service),
) -> list[BankAccountResponse]:
    return await service.list_accounts(current_user)


@router.post(
    "/link/initiate",
    response_model=BankLinkInitiateResponse,
    status_code=status.HTTP_200_OK,
    summary="Save bank details and send OTP to registered mobile",
)
async def initiate_bank_link(
    body: BankLinkInitiateRequest,
    current_user: User = Depends(get_current_user),
    service: BankAccountService = Depends(get_bank_account_service),
) -> BankLinkInitiateResponse:
    return await service.initiate_link(current_user, body)


@router.post(
    "/link/verify",
    response_model=BankAccountResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify OTP and link bank account",
)
async def verify_bank_link(
    body: BankLinkVerifyRequest,
    current_user: User = Depends(get_current_user),
    service: BankAccountService = Depends(get_bank_account_service),
) -> BankAccountResponse:
    return await service.verify_link(current_user, body.otp)


@router.get("/ifsc/banks", summary="List banks for IFSC lookup")
async def list_ifsc_banks(
    ifsc_service: IfscService = Depends(get_ifsc_service),
) -> dict[str, str]:
    return await ifsc_service.list_banks()


@router.get("/ifsc/banks/{bank}/states", summary="List states for a bank")
async def list_ifsc_states(
    bank: str,
    ifsc_service: IfscService = Depends(get_ifsc_service),
) -> list[str]:
    return await ifsc_service.list_states(bank)


@router.get(
    "/ifsc/banks/{bank}/states/{state}/districts",
    summary="List districts for bank and state",
)
async def list_ifsc_districts(
    bank: str,
    state: str,
    ifsc_service: IfscService = Depends(get_ifsc_service),
) -> list[str]:
    return await ifsc_service.list_districts(bank, state)


@router.get(
    "/ifsc/banks/{bank}/states/{state}/districts/{district}/branches",
    summary="List branches with IFSC codes",
)
async def list_ifsc_branches(
    bank: str,
    state: str,
    district: str,
    ifsc_service: IfscService = Depends(get_ifsc_service),
) -> list[dict[str, str]]:
    return await ifsc_service.list_branches(bank, state, district)


@router.get(
    "/ifsc/{code}",
    response_model=IfscLookupResponse,
    summary="Lookup IFSC code details",
)
async def lookup_ifsc(
    code: str,
    ifsc_service: IfscService = Depends(get_ifsc_service),
) -> IfscLookupResponse:
    data = await ifsc_service.lookup_ifsc(code)
    return IfscLookupResponse(
        bank=str(data.get("BANK") or ""),
        branch=str(data.get("BRANCH") or ""),
        ifsc=str(data.get("IFSC") or code).upper(),
        address=str(data.get("ADDRESS") or "") or None,
        city=str(data.get("CITY") or "") or None,
        state=str(data.get("STATE") or "") or None,
    )
