from pydantic import BaseModel
from datetime import date
from typing import Optional


class DisasterLocationCreate(BaseModel):
    province: str
    district: str
    tehsil: Optional[str] = None
    affected_population: int = 0
    gps_latitude: Optional[float] = None
    gps_longitude: Optional[float] = None


class DisasterLocationResponse(BaseModel):
    location_id: int
    province: str
    district: str
    tehsil: Optional[str]
    affected_population: int
    gps_latitude: Optional[float]
    gps_longitude: Optional[float]
    location_status: str

    class Config:
        from_attributes = True


class DisasterCreate(BaseModel):
    disaster_type_id: int
    disaster_name: str
    severity_level: str = "Medium"
    declaration_date: date
    projected_end_date: Optional[date] = None
    description: Optional[str] = None
    locations: list[DisasterLocationCreate] = []


class DisasterResponse(BaseModel):
    disaster_id: int
    disaster_type_id: int
    disaster_name: str
    severity_level: str
    declaration_date: date
    projected_end_date: Optional[date]
    status: str
    description: Optional[str]

    class Config:
        from_attributes = True


class DisasterDetailResponse(DisasterResponse):
    locations: list[DisasterLocationResponse] = []


class DisasterImpactResponse(BaseModel):
    disaster_id: int
    disaster_name: str
    disaster_type: str
    severity_level: str
    declaration_date: date
    status: str
    affected_locations: int
    total_affected_population: int
    registered_beneficiaries: int
    active_organizations: int
    total_units_distributed: int
