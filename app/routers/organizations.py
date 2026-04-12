from fastapi import APIRouter, HTTPException
from app.database import get_connection, release_connection
from app.schemas.organizations import (
    OrganizationCreate, OrganizationResponse, OrganizationLeaderboardResponse,
)

router = APIRouter(prefix="/organizations", tags=["Organizations"])


@router.post("/", response_model=OrganizationResponse, status_code=201)
def create_organization(data: OrganizationCreate):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO organization (org_category_id, org_name, registration_number,
               contact_email, contact_phone, government_tier, international_flag,
               registration_authority)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING *""",
            (data.org_category_id, data.org_name, data.registration_number,
             data.contact_email, data.contact_phone, data.government_tier,
             data.international_flag, data.registration_authority),
        )
        row = cur.fetchone()
        conn.commit()
        cur.close()
        return _map_org(row)
    finally:
        release_connection(conn)


@router.get("/", response_model=list[OrganizationResponse])
def list_organizations(category_id: int | None = None, approval_status: str | None = None):
    conn = get_connection()
    try:
        cur = conn.cursor()
        query = "SELECT * FROM organization WHERE 1=1"
        params = []
        if category_id:
            query += " AND org_category_id = %s"
            params.append(category_id)
        if approval_status:
            query += " AND approval_status = %s"
            params.append(approval_status)
        query += " ORDER BY org_name"
        cur.execute(query, params)
        rows = cur.fetchall()
        cur.close()
        return [_map_org(r) for r in rows]
    finally:
        release_connection(conn)


@router.get("/{org_id}", response_model=OrganizationResponse)
def get_organization(org_id: int):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM organization WHERE org_id = %s", (org_id,))
        row = cur.fetchone()
        cur.close()
        if not row:
            raise HTTPException(404, "Organization not found")
        return _map_org(row)
    finally:
        release_connection(conn)


@router.get("/leaderboard", response_model=list[OrganizationLeaderboardResponse])
def leaderboard():
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM v_org_fulfillment_leaderboard")
        rows = cur.fetchall()
        cur.close()
        return [_map_leader(r) for r in rows]
    finally:
        release_connection(conn)


def _map_org(row):
    return OrganizationResponse(
        org_id=row[0], org_category_id=row[1], org_name=row[2],
        registration_number=row[3], contact_email=row[4], contact_phone=row[5],
        approval_status=row[6], approval_date=row[7], government_tier=row[8],
        international_flag=row[9], registration_authority=row[10],
    )


def _map_leader(row):
    return OrganizationLeaderboardResponse(
        org_id=row[0], org_name=row[1], category_name=row[2],
        total_commitments=row[3], total_units_delivered=row[4],
        total_units_committed=row[5], reliability_pct=row[6],
    )
