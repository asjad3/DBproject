from fastapi import APIRouter, HTTPException
from app.database import get_cursor
from app.schemas.beneficiaries import (
    BeneficiaryCreate, BeneficiaryResponse,
    AidDistributionCreate, AidHistoryResponse,
)

router = APIRouter(prefix="/beneficiaries", tags=["Beneficiaries"])


@router.post("/", response_model=BeneficiaryResponse, status_code=201)
def create_beneficiary(data: BeneficiaryCreate):
    with get_cursor() as cur:
        cur.execute(
            """INSERT INTO beneficiary (location_id, cnic_or_id, full_name,
               contact_number, family_size, address_province, address_district,
               address_street)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING *""",
            (data.location_id, data.cnic_or_id, data.full_name,
             data.contact_number, data.family_size, data.address_province,
             data.address_district, data.address_street),
        )
        row = cur.fetchone()
        return _map_beneficiary(row)


@router.get("/", response_model=list[BeneficiaryResponse])
def list_beneficiaries(location_id: int | None = None):
    with get_cursor() as cur:
        if location_id:
            cur.execute(
                "SELECT * FROM beneficiary WHERE location_id = %s ORDER BY registration_date DESC",
                (location_id,),
            )
        else:
            cur.execute("SELECT * FROM beneficiary ORDER BY registration_date DESC")
        rows = cur.fetchall()
        return [_map_beneficiary(r) for r in rows]


@router.get("/{beneficiary_id}", response_model=BeneficiaryResponse)
def get_beneficiary(beneficiary_id: int):
    with get_cursor() as cur:
        cur.execute("SELECT * FROM beneficiary WHERE beneficiary_id = %s", (beneficiary_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(404, "Beneficiary not found")
        return _map_beneficiary(row)


@router.post("/{beneficiary_id}/aid", status_code=201)
def record_aid_distribution(beneficiary_id: int, data: AidDistributionCreate):
    with get_cursor() as cur:
        cur.execute(
            """INSERT INTO aid_distribution (beneficiary_id, product_id, program_id,
               org_id, team_id, quantity_distributed, distribution_date, notes)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            (beneficiary_id, data.product_id, data.program_id, data.org_id,
             data.team_id, data.quantity_distributed, data.distribution_date,
             data.notes),
        )
        return {"message": "Aid distribution recorded successfully"}


@router.get("/{beneficiary_id}/history", response_model=list[AidHistoryResponse])
def aid_history(beneficiary_id: int):
    with get_cursor() as cur:
        cur.execute(
            "SELECT * FROM v_beneficiary_aid_history WHERE beneficiary_id = %s",
            (beneficiary_id,),
        )
        rows = cur.fetchall()
        return [_map_history(r) for r in rows]


def _map_beneficiary(row):
    return BeneficiaryResponse(
        beneficiary_id=row[0], location_id=row[1], cnic_or_id=row[2],
        full_name=row[3], contact_number=row[4], family_size=row[5],
        address_province=row[6], address_district=row[7], address_street=row[8],
        registration_date=row[9], displacement_status=row[10],
    )


def _map_history(row):
    return AidHistoryResponse(
        beneficiary_id=row[0], full_name=row[1], cnic_or_id=row[2],
        family_size=row[3], district=row[4], province=row[5],
        product_name=row[6], product_category=row[7], unit_of_measure=row[8],
        quantity_distributed=row[9], distribution_date=row[10],
        distributing_org=row[11], distributing_team=row[12], program_name=row[13],
    )
