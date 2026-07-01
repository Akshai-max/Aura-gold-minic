from pydantic import BaseModel, Field


class AndroidAppReleaseResponse(BaseModel):
    version_name: str = Field(
        ...,
        description="Human-readable version (matches pubspec version name).",
    )
    version_code: int = Field(
        ...,
        ge=1,
        description="Android build number (matches pubspec +N). Must increase each release.",
    )
    apk_url: str = Field(..., description="Direct HTTPS URL to the release APK file.")
    release_notes: str = Field(
        default="",
        description="Short summary shown in the in-app update dialog.",
    )
    force_update: bool = Field(
        default=False,
        description="When true, users cannot dismiss the update prompt.",
    )
