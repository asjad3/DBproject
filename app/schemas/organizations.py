from pydantic import BaseModel, ConfigDict
from datetime import date


class OrganizationCreate(BaseModel):
    org_category_id: int
    org_name: str
    registration_number: str | None = None
    contact_email: str
    contact_phone: str | None = None
    government_tier: str | None = None
    international_flag: bool | None = None
    registration_authority: str | None = None


class OrganizationResponse(BaseModel):
    org_id: int
    org_category_id: int
    org_name: str
    registration_number: str | None
    contact_email: str
    contact_phone: str | None
    approval_status: str
    approved_by_admin_id: int | None
    approval_date: date | None
    government_tier: str | None
    international_flag: bool | None
    registration_authority: str | None

    model_config = ConfigDict(from_attributes=True)


class OrganizationLeaderboardResponse(BaseModel):
    org_id: int
    org_name: str
    category_name: str
    total_commitments: int
    total_units_delivered: int
    total_units_committed: int
    reliability_pct: float | None

    model_config = ConfigDict(from_attributes=True)
