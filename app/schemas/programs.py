from pydantic import BaseModel, ConfigDict
from datetime import date


class ProgramCreate(BaseModel):
    disaster_id: int
    program_name: str
    objectives: str | None = None
    start_date: date
    end_date: date | None = None


class ProgramResponse(BaseModel):
    program_id: int
    disaster_id: int
    program_name: str
    objectives: str | None
    start_date: date
    end_date: date | None
    status: str

    model_config = ConfigDict(from_attributes=True)


class ActiveProgramResponse(BaseModel):
    program_id: int
    program_name: str
    disaster_name: str
    severity_level: str
    start_date: date
    end_date: date | None
    status: str
    enrolled_org_count: int
    total_requirements: int

    model_config = ConfigDict(from_attributes=True)


class EnrollmentRequest(BaseModel):
    org_id: int


class GapReportItem(BaseModel):
    requirement_id: int
    location_district: str
    product_name: str
    quantity_required: int
    quantity_fulfilled: int
    fulfillment_pct: float | None
    gap_units: int
    priority: str

    model_config = ConfigDict(from_attributes=True)
