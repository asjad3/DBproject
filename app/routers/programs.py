from fastapi import APIRouter, HTTPException
from app.database import get_connection, release_connection
from app.schemas.programs import (
    ProgramCreate, ProgramResponse, ActiveProgramResponse,
    EnrollmentRequest, GapReportItem,
)

router = APIRouter(prefix="/programs", tags=["Relief Programs"])


@router.post("/", response_model=ProgramResponse, status_code=201)
def create_program(data: ProgramCreate):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO relief_program (disaster_id, program_name, objectives,
               start_date, end_date)
               VALUES (%s, %s, %s, %s, %s) RETURNING *""",
            (data.disaster_id, data.program_name, data.objectives,
             data.start_date, data.end_date),
        )
        row = cur.fetchone()
        conn.commit()
        cur.close()
        return _map_program(row)
    finally:
        release_connection(conn)


@router.get("/", response_model=list[ProgramResponse])
def list_programs(status: str | None = None):
    conn = get_connection()
    try:
        cur = conn.cursor()
        if status:
            cur.execute(
                "SELECT * FROM relief_program WHERE status = %s ORDER BY start_date DESC",
                (status,),
            )
        else:
            cur.execute("SELECT * FROM relief_program ORDER BY start_date DESC")
        rows = cur.fetchall()
        cur.close()
        return [_map_program(r) for r in rows]
    finally:
        release_connection(conn)


@router.get("/active", response_model=list[ActiveProgramResponse])
def active_programs():
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM v_active_program_summary")
        rows = cur.fetchall()
        cur.close()
        return [_map_active(r) for r in rows]
    finally:
        release_connection(conn)


@router.post("/{program_id}/enroll", status_code=201)
def enroll_organization(program_id: int, data: EnrollmentRequest):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "CALL sp_register_org_for_program(%s, %s)",
            (data.org_id, program_id),
        )
        conn.commit()
        cur.close()
        return {"message": f"Organization {data.org_id} enrolled in program {program_id}"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(400, str(e))
    finally:
        release_connection(conn)


@router.get("/{program_id}/gap-report", response_model=list[GapReportItem])
def gap_report(program_id: int, threshold: float = 70):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT * FROM sp_requirement_gap_report(%s, %s)",
            (program_id, threshold),
        )
        rows = cur.fetchall()
        cur.close()
        return [_map_gap(r) for r in rows]
    finally:
        release_connection(conn)


def _map_program(row):
    return ProgramResponse(
        program_id=row[0], disaster_id=row[1], program_name=row[2],
        objectives=row[3], start_date=row[4], end_date=row[5], status=row[6],
    )


def _map_active(row):
    return ActiveProgramResponse(
        program_id=row[0], program_name=row[1], disaster_name=row[2],
        severity_level=row[3], start_date=row[4], end_date=row[5],
        status=row[6], enrolled_org_count=row[7], total_requirements=row[8],
    )


def _map_gap(row):
    return GapReportItem(
        requirement_id=row[0], location_district=row[1], product_name=row[2],
        quantity_required=row[3], quantity_fulfilled=row[4],
        fulfillment_pct=row[5], gap_units=row[6], priority=row[7],
    )
