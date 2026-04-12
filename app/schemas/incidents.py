from pydantic import BaseModel, ConfigDict
from datetime import date


class IncidentReportCreate(BaseModel):
    team_id: int
    location_id: int
    report_title: str
    report_body: str
    report_date: date | None = None
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

    model_config = ConfigDict(from_attributes=True)
