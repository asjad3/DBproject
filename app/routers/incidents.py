from fastapi import APIRouter, HTTPException
from app.database import get_cursor
from app.schemas.incidents import IncidentReportCreate, IncidentReportResponse

router = APIRouter(prefix="/incidents", tags=["Incident Reports"])


@router.post("/", response_model=IncidentReportResponse, status_code=201)
def create_incident(data: IncidentReportCreate):
    with get_cursor() as cur:
        cur.execute(
            """INSERT INTO incident_report (team_id, location_id, report_title,
               report_body, report_date, severity_flag, submitted_by)
               VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING *""",
            (data.team_id, data.location_id, data.report_title,
             data.report_body, data.report_date, data.severity_flag,
             data.submitted_by),
        )
        row = cur.fetchone()
        return _map_report(row)


@router.get("/", response_model=list[IncidentReportResponse])
def list_incidents(
    severity: str | None = None,
    location_id: int | None = None,
    date_from: str | None = None,
    date_to: str | None = None,
    limit: int = 50,
):
    conditions = []
    params = []
    if severity:
        conditions.append("severity_flag = %s")
        params.append(severity)
    if location_id:
        conditions.append("location_id = %s")
        params.append(location_id)
    if date_from:
        conditions.append("report_date >= %s")
        params.append(date_from)
    if date_to:
        conditions.append("report_date <= %s")
        params.append(date_to)

    where = " AND ".join(conditions) if conditions else "1=1"
    params.append(limit)

    with get_cursor() as cur:
        cur.execute(f"SELECT * FROM incident_report WHERE {where} ORDER BY report_date DESC LIMIT %s", params)
        rows = cur.fetchall()
        return [_map_report(r) for r in rows]


@router.get("/{report_id}", response_model=IncidentReportResponse)
def get_incident(report_id: int):
    with get_cursor() as cur:
        cur.execute("SELECT * FROM incident_report WHERE report_id = %s", (report_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(404, "Incident report not found")
        return _map_report(row)


def _map_report(row):
    return IncidentReportResponse(
        report_id=row[0], team_id=row[1], location_id=row[2],
        report_title=row[3], report_body=row[4], report_date=row[5],
        severity_flag=row[6], submitted_by=row[7],
    )
