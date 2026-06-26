import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select

from app.core.exceptions import NotFoundException, ValidationException
from app.models.gold_sell_inquiry import GoldSellInquiry
from app.models.user import User
from app.repositories.gold_sell_inquiry import GoldSellInquiryRepository
from app.repositories.user import UserRepository
from app.schemas.gold_sell_inquiry import (
    GoldSellInquiryCreate,
    GoldSellInquiryListResponse,
    GoldSellInquiryRespond,
    GoldSellInquiryResponse,
)
from app.services.gold_scheme import GoldSchemeService
from app.services.notification import NotificationService


class GoldSellInquiryService:
    def __init__(
        self,
        inquiry_repo: GoldSellInquiryRepository,
        user_repo: UserRepository,
        notification_service: NotificationService,
    ):
        self.inquiry_repo = inquiry_repo
        self.user_repo = user_repo
        self.notification_service = notification_service

    def _to_response(self, inquiry: GoldSellInquiry) -> GoldSellInquiryResponse:
        user_email = inquiry.user.email if inquiry.user else None
        return GoldSellInquiryResponse(
            id=inquiry.id,
            user_id=inquiry.user_id,
            name=inquiry.name,
            mobile_number=inquiry.mobile_number,
            message=inquiry.message,
            status=inquiry.status,
            admin_response=inquiry.admin_response,
            responded_by_user_id=inquiry.responded_by_user_id,
            responded_at=inquiry.responded_at,
            created_at=inquiry.created_at,
            updated_at=inquiry.updated_at,
            user_email=user_email,
        )

    async def _notify_admins(self, inquiry: GoldSellInquiry) -> None:
        admin_ids = set(
            await self.user_repo.get_user_ids_with_permission("transaction.view")
        )
        superuser_query = select(User.id).where(
            User.is_superuser.is_(True),
            User.is_deleted.is_(False),
            User.is_active.is_(True),
        )
        result = await self.user_repo.db.execute(superuser_query)
        admin_ids.update(result.scalars().all())

        title = "New gold sell inquiry"
        message = (
            f"{inquiry.name} ({inquiry.mobile_number}) submitted a gold sell request."
        )
        for admin_id in admin_ids:
            if admin_id == inquiry.user_id:
                continue
            await self.notification_service.create_notification(
                user_id=admin_id,
                title=title,
                message=message,
                category=NotificationService.CATEGORY_SYSTEM,
                metadata={"inquiry_id": str(inquiry.id), "type": "gold_sell_inquiry"},
            )

    async def create_inquiry(
        self,
        user: User,
        body: GoldSellInquiryCreate,
    ) -> GoldSellInquiryResponse:
        if not GoldSchemeService.can_sell_gold(user):
            reason = GoldSchemeService.sell_locked_reason(user)
            raise ValidationException(
                reason or "Buy gold before submitting a sell request."
            )

        inquiry = await self.inquiry_repo.create(
            {
                "user_id": user.id,
                "name": body.name,
                "mobile_number": body.mobile_number,
                "message": body.message,
                "status": "pending",
            }
        )
        inquiry.user = user
        await self._notify_admins(inquiry)
        return self._to_response(inquiry)

    async def list_my_inquiries(
        self,
        user: User,
        skip: int = 0,
        limit: int = 50,
    ) -> GoldSellInquiryListResponse:
        items = await self.inquiry_repo.list_for_user(user.id, skip=skip, limit=limit)
        return GoldSellInquiryListResponse(
            items=[self._to_response(item) for item in items],
            total=len(items),
            skip=skip,
            limit=limit,
        )

    async def list_inquiries(
        self,
        skip: int = 0,
        limit: int = 50,
        status: Optional[str] = None,
    ) -> GoldSellInquiryListResponse:
        items = await self.inquiry_repo.list_all(skip=skip, limit=limit, status=status)
        total = await self.inquiry_repo.count_all(status=status)
        return GoldSellInquiryListResponse(
            items=[self._to_response(item) for item in items],
            total=total,
            skip=skip,
            limit=limit,
        )

    async def respond_to_inquiry(
        self,
        inquiry_id: uuid.UUID,
        admin_user: User,
        body: GoldSellInquiryRespond,
    ) -> GoldSellInquiryResponse:
        inquiry = await self.inquiry_repo.get_with_user(inquiry_id)
        if not inquiry:
            raise NotFoundException(message="Sell inquiry not found")

        inquiry = await self.inquiry_repo.update(
            inquiry,
            {
                "admin_response": body.admin_response,
                "status": body.status,
                "responded_by_user_id": admin_user.id,
                "responded_at": datetime.now(timezone.utc),
            },
        )

        await self.notification_service.create_notification(
            user_id=inquiry.user_id,
            title="Update on your gold sell request",
            message=body.admin_response,
            category=NotificationService.CATEGORY_SYSTEM,
            metadata={"inquiry_id": str(inquiry.id), "type": "gold_sell_inquiry"},
        )

        return self._to_response(inquiry)
