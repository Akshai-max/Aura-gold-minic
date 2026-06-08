from typing import List
from pydantic import BaseModel
from app.schemas.audit_log import AuditLogResponse
from app.schemas.notification import NotificationResponse


class LoginStatistics(BaseModel):
    today: int
    week: int
    month: int


class ActivityTrendPoint(BaseModel):
    label: str
    count: int


class DashboardStatsResponse(BaseModel):
    recent_activity: List[AuditLogResponse]
    unread_notifications: int
    security_alerts: List[AuditLogResponse]
    recent_notifications: List[NotificationResponse]
    login_statistics: LoginStatistics
    activity_trend: List[ActivityTrendPoint] = []
