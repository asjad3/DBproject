from pydantic import BaseModel, ConfigDict
from datetime import date


class BeneficiaryCreate(BaseModel):
    location_id: int
    cnic_or_id: str
    full_name: str
    contact_number: str | None = None
    family_size: int = 1
    address_province: str | None = None
    address_district: str | None = None
    address_street: str | None = None


class BeneficiaryResponse(BaseModel):
    beneficiary_id: int
    location_id: int
    cnic_or_id: str
    full_name: str
    contact_number: str | None
    family_size: int
    address_province: str | None
    address_district: str | None
    address_street: str | None
    registration_date: date
    displacement_status: str

    model_config = ConfigDict(from_attributes=True)


class AidDistributionCreate(BaseModel):
    product_id: int
    program_id: int
    org_id: int
    team_id: int | None = None
    quantity_distributed: int
    distribution_date: date | None = None
    notes: str | None = None


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
    distributing_team: str | None
    program_name: str

    model_config = ConfigDict(from_attributes=True)
