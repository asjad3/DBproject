from fastapi import APIRouter, HTTPException
from app.database import get_connection, release_connection
from app.schemas.disasters import (
    DisasterCreate, DisasterResponse, DisasterDetailResponse,
    DisasterLocationResponse, DisasterImpactResponse,
)

router = APIRouter(prefix="/disasters", tags=["Disasters"])


@router.post("/", response_model=DisasterResponse, status_code=201)
def create_disaster(data: DisasterCreate):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO disaster (disaster_type_id, disaster_name, severity_level,
               declaration_date, projected_end_date, description)
               VALUES (%s, %s, %s, %s, %s, %s) RETURNING *""",
            (data.disaster_type_id, data.disaster_name, data.severity_level,
             data.declaration_date, data.projected_end_date, data.description),
        )
        row = cur.fetchone()
        disaster_id = row[0]

        for loc in data.locations:
            cur.execute(
                """INSERT INTO disaster_location (disaster_id, province, district, tehsil,
                   affected_population, gps_latitude, gps_longitude)
                   VALUES (%s, %s, %s, %s, %s, %s, %s)""",
                (disaster_id, loc.province, loc.district, loc.tehsil,
                 loc.affected_population, loc.gps_latitude, loc.gps_longitude),
            )

        conn.commit()
        cur.execute("SELECT * FROM disaster WHERE disaster_id = %s", (disaster_id,))
        row = cur.fetchone()
        cur.close()
        return _map_disaster(row)
    finally:
        release_connection(conn)


@router.get("/", response_model=list[DisasterResponse])
def list_disasters(status: str | None = None):
    conn = get_connection()
    try:
        cur = conn.cursor()
        if status:
            cur.execute("SELECT * FROM disaster WHERE status = %s ORDER BY declaration_date DESC", (status,))
        else:
            cur.execute("SELECT * FROM disaster ORDER BY declaration_date DESC")
        rows = cur.fetchall()
        cur.close()
        return [_map_disaster(r) for r in rows]
    finally:
        release_connection(conn)


@router.get("/{disaster_id}", response_model=DisasterDetailResponse)
def get_disaster(disaster_id: int):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM disaster WHERE disaster_id = %s", (disaster_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(404, "Disaster not found")

        cur.execute(
            "SELECT * FROM disaster_location WHERE disaster_id = %s",
            (disaster_id,),
        )
        locs = [_map_location(r) for r in cur.fetchall()]
        cur.close()

        d = _map_disaster(row)
        return DisasterDetailResponse(**d.model_dump(), locations=locs)
    finally:
        release_connection(conn)


@router.get("/{disaster_id}/impact", response_model=DisasterImpactResponse)
def get_disaster_impact(disaster_id: int):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT * FROM v_disaster_impact_summary WHERE disaster_id = %s",
            (disaster_id,),
        )
        row = cur.fetchone()
        cur.close()
        if not row:
            raise HTTPException(404, "Disaster not found")
        return _map_impact(row)
    finally:
        release_connection(conn)


def _map_disaster(row):
    return DisasterResponse(
        disaster_id=row[0], disaster_type_id=row[1], disaster_name=row[2],
        severity_level=row[3], declaration_date=row[4], projected_end_date=row[5],
        status=row[6], description=row[7],
    )


def _map_location(row):
    return DisasterLocationResponse(
        location_id=row[0], province=row[2], district=row[3], tehsil=row[4],
        affected_population=row[5], gps_latitude=row[6], gps_longitude=row[7],
        location_status=row[8],
    )


def _map_impact(row):
    return DisasterImpactResponse(
        disaster_id=row[0], disaster_name=row[1], disaster_type=row[2],
        severity_level=row[3], declaration_date=row[4], status=row[5],
        affected_locations=row[6], total_affected_population=row[7],
        registered_beneficiaries=row[8], active_organizations=row[9],
        total_units_distributed=row[10],
    )
