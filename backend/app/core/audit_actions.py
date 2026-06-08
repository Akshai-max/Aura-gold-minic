"""Canonical audit action type constants."""

LOGIN_SUCCESS = "login_success"
LOGIN_FAILURE = "login_failure"
LOGOUT = "logout"
USER_CREATE = "user_create"
USER_UPDATE = "user_update"
USER_DELETE = "user_delete"
ROLE_ASSIGN = "role_assign"
ROLE_REMOVE = "role_remove"
PERMISSION_ASSIGN = "permission_assign"
PERMISSION_REMOVE = "permission_remove"
PROFILE_UPDATE = "profile_update"
PASSWORD_CHANGE = "password_change"
AUDIT_EXPORT = "audit_export"
AVATAR_UPDATE = "avatar_update"
SETTINGS_UPDATE = "settings_update"

ALL_ACTIONS = [
    LOGIN_SUCCESS,
    LOGIN_FAILURE,
    LOGOUT,
    USER_CREATE,
    USER_UPDATE,
    USER_DELETE,
    ROLE_ASSIGN,
    ROLE_REMOVE,
    PERMISSION_ASSIGN,
    PERMISSION_REMOVE,
    PROFILE_UPDATE,
    PASSWORD_CHANGE,
    AUDIT_EXPORT,
    AVATAR_UPDATE,
    SETTINGS_UPDATE,
]
