from pydantic import BaseModel
from datetime import date
from typing import Optional


class ProgramCreate(BaseModel):
    disaster_id: int
    program_name: str
    objectives: Optional[str] = None
    start_date: date
    end_date: Optional[date] = None


class ProgramResponse(BaseModel):
    program_id: int
    disaster_id: int
    program_name: str
    objectives: Optional[str]
    start_date: date
    end_date: Optional[date]
    status: str

    class Config:
        from_attributes = True


class ActiveProgramResponse(BaseModel):
    program_id: int
    program_name: str
    disaster_name: str
    severity_level: str
    start_date: date
    end_date: Optional[date]
    status: str
    enrolled_org_count: int
    total_requirements: int


class EnrollmentRequest(BaseModel):
    org_id: int


class GapReportItem(BaseModel):
    requirement_id: int
    location_district: str
    product_name: str
    quantity_required: int
    quantity_fulfilled: int
    fulfillment_pct: Optional[float]
    gap_units: int
    priority: str
