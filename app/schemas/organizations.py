from pydantic import BaseModel
from datetime import date
from typing import Optional


class OrganizationCreate(BaseModel):
    org_category_id: int
    org_name: str
    registration_number: Optional[str] = None
    contact_email: str
    contact_phone: Optional[str] = None
    government_tier: Optional[str] = None
    international_flag: Optional[bool] = None
    registration_authority: Optional[str] = None


class OrganizationResponse(BaseModel):
    org_id: int
    org_category_id: int
    org_name: str
    registration_number: Optional[str]
    contact_email: str
    contact_phone: Optional[str]
    approval_status: str
    approval_date: Optional[date]
    government_tier: Optional[str]
    international_flag: Optional[bool]
    registration_authority: Optional[str]

    class Config:
        from_attributes = True


class OrganizationLeaderboardResponse(BaseModel):
    org_id: int
    org_name: str
    category_name: str
    total_commitments: int
    total_units_delivered: int
    total_units_committed: int
    reliability_pct: Optional[float]
