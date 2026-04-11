import os
from dotenv import load_dotenv

load_dotenv()

def get_reports_from_supabase():
    from supabase import create_client

    client = create_client(
        os.getenv("SUPABASE_URL"),
        os.getenv("SUPABASE_KEY")
    )

    response = client.table("incident_report").select("""
        report_id,
        report_title,
        report_body,
        report_date,
        severity_flag,
        submitted_by,
        disaster_location (district, province),
        field_team (
            team_name,
            organization (org_name)
        )
    """).execute()

    return [
        {
            "report_id":    r["report_id"],
            "report_title": r["report_title"],
            "report_body":  r["report_body"],
            "report_date":  str(r["report_date"]),
            "severity_flag": r["severity_flag"],
            "submitted_by": r["submitted_by"],
            "district":     r["disaster_location"]["district"],
            "province":     r["disaster_location"]["province"],
            "team_name":    r["field_team"]["team_name"],
            "org_name":     r["field_team"]["organization"]["org_name"],
        }
        for r in response.data
    ]


def get_reports_from_postgres():
    import psycopg2
    import psycopg2.extras

    conn = psycopg2.connect(
        host=os.getenv("PG_HOST", "localhost"),
        port=os.getenv("PG_PORT", 5432),
        user=os.getenv("PG_USER", "new_user"),
        password=os.getenv("PG_PASSWORD", "strong_password"),
        database=os.getenv("PG_DATABASE", "disasterlink")
    )

    cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cursor.execute("""
        SELECT
            ir.report_id,
            ir.report_title,
            ir.report_body,
            ir.report_date,
            ir.severity_flag,
            ir.submitted_by,
            dl.district,
            dl.province,
            ft.team_name,
            o.org_name
        FROM incident_report ir
        JOIN disaster_location dl ON ir.location_id = dl.location_id
        JOIN field_team ft ON ir.team_id = ft.team_id
        JOIN organization o ON ft.org_id = o.org_id
    """)

    reports = cursor.fetchall()
    cursor.close()
    conn.close()

    return [
        {
            "report_id":    r["report_id"],
            "report_title": r["report_title"],
            "report_body":  r["report_body"],
            "report_date":  str(r["report_date"]),
            "severity_flag": r["severity_flag"],
            "submitted_by": r["submitted_by"],
            "district":     r["district"],
            "province":     r["province"],
            "team_name":    r["team_name"],
            "org_name":     r["org_name"],
        }
        for r in reports
    ]


def get_reports():
    USE_MOCK = False  

    if USE_MOCK:
        from mock_data import MOCK_REPORTS
        print("Using mock data")
        return MOCK_REPORTS

    db_type = os.getenv("DB_TYPE", "postgres").lower()

    if db_type == "supabase":
        return get_reports_from_supabase()
    elif db_type == "mysql":
        return get_reports_from_mysql()
    else:
        return get_reports_from_postgres()

if __name__ == "__main__":
    reports = get_reports()
    print(f"Fetched {len(reports)} reports")
    for r in reports:
        print(f"  - [{r['severity_flag']}] {r['report_title']}")
