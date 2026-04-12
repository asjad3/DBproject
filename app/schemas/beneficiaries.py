from pydantic import BaseModel
from datetime import date
from typing import Optional


class BeneficiaryCreate(BaseModel):
    location_id: int
    cnic_or_id: str
    full_name: str
    contact_number: Optional[str] = None
    family_size: int = 1
    address_province: Optional[str] = None
    address_district: Optional[str] = None
    address_street: Optional[str] = None


class BeneficiaryResponse(BaseModel):
    beneficiary_id: int
    location_id: int
    cnic_or_id: str
    full_name: str
    contact_number: Optional[str]
    family_size: int
    address_province: Optional[str]
    address_district: Optional[str]
    address_street: Optional[str]
    registration_date: date
    displacement_status: str

    class Config:
        from_attributes = True


class AidDistributionCreate(BaseModel):
    product_id: int
    program_id: int
    org_id: int
    team_id: Optional[int] = None
    quantity_distributed: int
    distribution_date: Optional[date] = None
    notes: Optional[str] = None


class AidHistoryResponse(BaseModel):
    beneficiary_id: int
    full_name: str
    cnic_or_id: str
    family_size: int
    district: str
    province: str
    product_name: str
    product_category: str
    unit_of_measure: str
    quantity_distributed: int
    distribution_date: date
    distributing_org: str
    distributing_team: Optional[str]
    program_name: str
