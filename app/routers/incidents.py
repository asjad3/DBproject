from fastapi import APIRouter
from app.database import get_connection, release_connection
from app.schemas.incidents import IncidentReportCreate, IncidentReportResponse

router = APIRouter(prefix="/incidents", tags=["Incident Reports"])


@router.post("/", response_model=IncidentReportResponse, status_code=201)
def create_incident(data: IncidentReportCreate):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO incident_report (team_id, location_id, report_title,
               report_body, report_date, severity_flag, submitted_by)
               VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING *""",
            (data.team_id, data.location_id, data.report_title,
             data.report_body, data.report_date, data.severity_flag,
             data.submitted_by),
        )
        row = cur.fetchone()
        conn.commit()
        cur.close()
        return _map_report(row)
    finally:
        release_connection(conn)


@router.get("/", response_model=list[IncidentReportResponse])
def list_incidents(
    severity: str | None = None,
    location_id: int | None = None,
    date_from: str | None = None,
    date_to: str | None = None,
    limit: int = 50,
):
    conn = get_connection()
    try:
        cur = conn.cursor()
        query = "SELECT * FROM incident_report WHERE 1=1"
        params = []
        if severity:
            query += " AND severity_flag = %s"
            params.append(severity)
        if location_id:
            query += " AND location_id = %s"
            params.append(location_id)
        if date_from:
            query += " AND report_date >= %s"
            params.append(date_from)
        if date_to:
            query += " AND report_date <= %s"
            params.append(date_to)
        query += " ORDER BY report_date DESC LIMIT %s"
        params.append(limit)
        cur.execute(query, params)
        rows = cur.fetchall()
        cur.close()
        return [_map_report(r) for r in rows]
    finally:
        release_connection(conn)


@router.get("/{report_id}", response_model=IncidentReportResponse)
def get_incident(report_id: int):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM incident_report WHERE report_id = %s", (report_id,))
        row = cur.fetchone()
        cur.close()
        if not row:
            return None
        return _map_report(row)
    finally:
        release_connection(conn)


def _map_report(row):
    return IncidentReportResponse(
        report_id=row[0], team_id=row[1], location_id=row[2],
        report_title=row[3], report_body=row[4], report_date=row[5],
        severity_flag=row[6], submitted_by=row[7],
    )
