import re
from app.models.user import User

SPLIT_REGEX = re.compile(r"[:.]")


def user_has_permission(user: User, permission_name: str) -> bool:
    """Return True if the user has the given permission (or is superuser)."""
    if user.is_superuser:
        return True

    req_parts = SPLIT_REGEX.split(permission_name)
    for role in user.roles:
        for perm in role.permissions:
            if perm.name == permission_name:
                return True
            perm_parts = SPLIT_REGEX.split(perm.name)
            if (
                len(perm_parts) == 2
                and perm_parts[1] == "*"
                and len(req_parts) > 0
                and perm_parts[0] == req_parts[0]
            ):
                return True
    return False
