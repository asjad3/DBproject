from pydantic import BaseModel
from datetime import date
from typing import Optional


class IncidentReportCreate(BaseModel):
    team_id: int
    location_id: int
    report_title: str
    report_body: str
    report_date: Optional[date] = None
    severity_flag: str = "Info"
    submitted_by: str


class IncidentReportResponse(BaseModel):
    report_id: int
    team_id: int
    location_id: int
    report_title: str
    report_body: str
    report_date: date
    severity_flag: str
    submitted_by: str

    class Config:
        from_attributes = True
