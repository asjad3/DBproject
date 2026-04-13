from fastapi import APIRouter, HTTPException
from app.database import get_cursor
from app.schemas.organizations import (
    OrganizationCreate, OrganizationResponse, OrganizationLeaderboardResponse,
)

router = APIRouter(prefix="/organizations", tags=["Organizations"])


@router.post("/", response_model=OrganizationResponse, status_code=201)
def create_organization(data: OrganizationCreate):
    with get_cursor() as cur:
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
        return _map_org(row)


@router.get("/", response_model=list[OrganizationResponse])
def list_organizations(category_id: int | None = None, approval_status: str | None = None):
    conditions = []
    params = []
    if category_id:
        conditions.append("org_category_id = %s")
        params.append(category_id)
    if approval_status:
        conditions.append("approval_status = %s")
        params.append(approval_status)

    where = " AND ".join(conditions) if conditions else "1=1"

    with get_cursor() as cur:
        cur.execute(f"SELECT * FROM organization WHERE {where} ORDER BY org_name", params)
        rows = cur.fetchall()
        return [_map_org(r) for r in rows]


@router.get("/{org_id}", response_model=OrganizationResponse)
def get_organization(org_id: int):
    with get_cursor() as cur:
        cur.execute("SELECT * FROM organization WHERE org_id = %s", (org_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(404, "Organization not found")
        return _map_org(row)


@router.get("/leaderboard", response_model=list[OrganizationLeaderboardResponse])
def leaderboard():
    with get_cursor() as cur:
        cur.execute("SELECT * FROM v_org_fulfillment_leaderboard")
        rows = cur.fetchall()
        return [_map_leader(r) for r in rows]


def _map_org(row):
    return OrganizationResponse(
        org_id=row[0], org_category_id=row[1], org_name=row[2],
        registration_number=row[3], contact_email=row[4], contact_phone=row[5],
        approval_status=row[6], approved_by_admin_id=row[7], approval_date=row[8],
        government_tier=row[9], international_flag=row[10], registration_authority=row[11],
    )


def _map_leader(row):
    return OrganizationLeaderboardResponse(
        org_id=row[0], org_name=row[1], category_name=row[2],
        total_commitments=row[3], total_units_delivered=row[4],
        total_units_committed=row[5], reliability_pct=row[6],
    )
