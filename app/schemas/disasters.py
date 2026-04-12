from pydantic import BaseModel, ConfigDict
from datetime import date


class DisasterLocationCreate(BaseModel):
    province: str
    district: str
    tehsil: str | None = None
    affected_population: int = 0
    gps_latitude: float | None = None
    gps_longitude: float | None = None


class DisasterLocationResponse(BaseModel):
    location_id: int
    province: str
    district: str
    tehsil: str | None
    affected_population: int
    gps_latitude: float | None
    gps_longitude: float | None
    location_status: str

    model_config = ConfigDict(from_attributes=True)


class DisasterCreate(BaseModel):
    disaster_type_id: int
    disaster_name: str
    severity_level: str = "Medium"
    declaration_date: date
    projected_end_date: date | None = None
    description: str | None = None
    locations: list[DisasterLocationCreate] = []


class DisasterResponse(BaseModel):
    disaster_id: int
    disaster_type_id: int
    disaster_name: str
    severity_level: str
    declaration_date: date
    projected_end_date: date | None
    status: str
    description: str | None

    model_config = ConfigDict(from_attributes=True)


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

    model_config = ConfigDict(from_attributes=True)
