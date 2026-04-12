import streamlit as st
import pandas as pd
from datetime import date
from api import get, post
from components import stat_card, data_table, severity_color, format_date

st.set_page_config(page_title="DisasterLink", page_icon="🚨", layout="wide")
st.title("DisasterLink Dashboard")

page = st.sidebar.selectbox(
    "Navigate",
    ["Dashboard", "Disasters", "Organizations", "Programs", "Incident Reports", "AI Assistant"],
)

# ─── Dashboard ───────────────────────────────────────────────────────────────
if page == "Dashboard":
    try:
        disasters = get("/disasters")
        orgs = get("/organizations")
        beneficiaries = get("/beneficiaries")
        programs = get("/programs")

        col1, col2, col3, col4 = st.columns(4)
        with col1:
            stat_card("Total Disasters", len(disasters), "🌊")
        with col2:
            stat_card("Organizations", len(orgs), "🏢")
        with col3:
            stat_card("Beneficiaries", len(beneficiaries), "👥")
        with col4:
            stat_card("Programs", len(programs), "📋")

        st.divider()

        active = [d for d in disasters if d.get("status") == "Active"]
        if active:
            st.subheader("Active Disasters")
            for d in active:
                st.warning(f"**{d['disaster_name']}** — Severity: {d['severity_level']} | Declared: {format_date(d['declaration_date'])}")

        st.subheader("Recent Incident Reports")
        reports = get("/incidents", params={"limit": 10})
        if reports:
            df = pd.DataFrame([
                {
                    "Severity": f"{severity_color(r['severity_flag'])} {r['severity_flag']}",
                    "Title": r["report_title"],
                    "Date": format_date(r["report_date"]),
                    "Submitted By": r["submitted_by"],
                }
                for r in reports
            ])
            data_table(df)
    except Exception as e:
        st.error(f"Failed to load dashboard: {e}")

# ─── Disasters ───────────────────────────────────────────────────────────────
elif page == "Disasters":
    tab_list, tab_create = st.tabs(["All Disasters", "Create Disaster"])

    with tab_list:
        try:
            disasters = get("/disasters")
            if disasters:
                df = pd.DataFrame([
                    {
                        "ID": d["disaster_id"],
                        "Name": d["disaster_name"],
                        "Type ID": d["disaster_type_id"],
                        "Severity": d["severity_level"],
                        "Status": d["status"],
                        "Declared": format_date(d["declaration_date"]),
                        "End": format_date(d.get("projected_end_date")),
                    }
                    for d in disasters
                ])
                data_table(df)
            else:
                st.info("No disasters found.")
        except Exception as e:
            st.error(f"Error: {e}")

    with tab_create:
        with st.form("create_disaster"):
            name = st.text_input("Disaster Name")
            dtype = st.number_input("Disaster Type ID", min_value=1, value=1)
            severity = st.selectbox("Severity", ["Low", "Medium", "High", "Critical"])
            dec_date = st.date_input("Declaration Date", value=date.today())
            desc = st.text_area("Description")
            submitted = st.form_submit_button("Create")
            if submitted and name:
                try:
                    result = post("/disasters", {
                        "disaster_type_id": dtype,
                        "disaster_name": name,
                        "severity_level": severity,
                        "declaration_date": str(dec_date),
                        "description": desc,
                    })
                    st.success(f"Created: {result['disaster_name']}")
                except Exception as e:
                    st.error(f"Error: {e}")

# ─── Organizations ───────────────────────────────────────────────────────────
elif page == "Organizations":
    tab_list, tab_leaderboard = st.tabs(["All Organizations", "Fulfillment Leaderboard"])

    with tab_list:
        try:
            orgs = get("/organizations")
            if orgs:
                df = pd.DataFrame([
                    {
                        "ID": o["org_id"],
                        "Name": o["org_name"],
                        "Category": o["org_category_id"],
                        "Email": o["contact_email"],
                        "Status": o["approval_status"],
                    }
                    for o in orgs
                ])
                data_table(df)
        except Exception as e:
            st.error(f"Error: {e}")

    with tab_leaderboard:
        try:
            lb = get("/organizations/leaderboard")
            if lb:
                df = pd.DataFrame([
                    {
                        "Organization": o["org_name"],
                        "Category": o["category_name"],
                        "Commitments": o["total_commitments"],
                        "Delivered": o["total_units_delivered"],
                        "Committed": o["total_units_committed"],
                        "Reliability %": o["reliability_pct"],
                    }
                    for o in lb
                ])
                data_table(df)
        except Exception as e:
            st.error(f"Error: {e}")

# ─── Programs ────────────────────────────────────────────────────────────────
elif page == "Programs":
    tab_list, tab_active, tab_gap = st.tabs(["All Programs", "Active Programs", "Gap Report"])

    with tab_list:
        try:
            programs = get("/programs")
            if programs:
                df = pd.DataFrame([
                    {
                        "ID": p["program_id"],
                        "Name": p["program_name"],
                        "Disaster ID": p["disaster_id"],
                        "Status": p["status"],
                        "Start": format_date(p["start_date"]),
                        "End": format_date(p.get("end_date")),
                    }
                    for p in programs
                ])
                data_table(df)
        except Exception as e:
            st.error(f"Error: {e}")

    with tab_active:
        try:
            active = get("/programs/active")
            if active:
                df = pd.DataFrame([
                    {
                        "Program": a["program_name"],
                        "Disaster": a["disaster_name"],
                        "Severity": a["severity_level"],
                        "Orgs Enrolled": a["enrolled_org_count"],
                        "Requirements": a["total_requirements"],
                        "Start": format_date(a["start_date"]),
                    }
                    for a in active
                ])
                data_table(df)
        except Exception as e:
            st.error(f"Error: {e}")

    with tab_gap:
        prog_id = st.number_input("Program ID for Gap Report", min_value=1, value=1)
        threshold = st.slider("Fulfillment Threshold (%)", 0, 100, 70)
        if st.button("Generate Report"):
            try:
                gap = get(f"/programs/{prog_id}/gap-report", params={"threshold": threshold})
                if gap:
                    df = pd.DataFrame([
                        {
                            "Requirement": g["requirement_id"],
                            "District": g["location_district"],
                            "Product": g["product_name"],
                            "Required": g["quantity_required"],
                            "Fulfilled": g["quantity_fulfilled"],
                            "Fulfillment %": g["fulfillment_pct"],
                            "Gap": g["gap_units"],
                            "Priority": g["priority"],
                        }
                        for g in gap
                    ])
                    data_table(df)
                else:
                    st.info("All requirements are above the threshold.")
            except Exception as e:
                st.error(f"Error: {e}")

# ─── Incident Reports ────────────────────────────────────────────────────────
elif page == "Incident Reports":
    tab_list, tab_submit = st.tabs(["All Reports", "Submit Report"])

    with tab_list:
        try:
            severity_filter = st.selectbox("Filter by Severity", ["All", "Info", "Warning", "Critical"])
            params = {"limit": 50}
            if severity_filter != "All":
                params["severity"] = severity_filter
            reports = get("/incidents", params=params)
            if reports:
                for r in reports:
                    icon = severity_color(r["severity_flag"])
                    with st.expander(f"{icon} [{r['severity_flag']}] {r['report_title']} — {format_date(r['report_date'])}"):
                        st.write(r["report_body"])
                        st.caption(f"Submitted by: {r['submitted_by']} | Team: {r['team_id']} | Location: {r['location_id']}")
        except Exception as e:
            st.error(f"Error: {e}")

    with tab_submit:
        with st.form("submit_report"):
            team_id = st.number_input("Team ID", min_value=1, value=1)
            location_id = st.number_input("Location ID", min_value=1, value=1)
            title = st.text_input("Report Title")
            body = st.text_area("Report Body")
            sev = st.selectbox("Severity", ["Info", "Warning", "Critical"])
            submitter = st.text_input("Submitted By")
            submitted = st.form_submit_button("Submit Report")
            if submitted and title and body and submitter:
                try:
                    post("/incidents", {
                        "team_id": team_id,
                        "location_id": location_id,
                        "report_title": title,
                        "report_body": body,
                        "severity_flag": sev,
                        "submitted_by": submitter,
                    })
                    st.success("Report submitted successfully!")
                except Exception as e:
                    st.error(f"Error: {e}")

# ─── AI Assistant ────────────────────────────────────────────────────────────
elif page == "AI Assistant":
    st.subheader("DisasterLink AI Assistant")
    st.caption("Ask questions about incident reports. The AI will answer based on field reports in the database.")

    col1, col2 = st.columns([3, 1])
    with col2:
        if st.button("Re-ingest Reports"):
            try:
                result = post("/rag/ingest")
                st.success(f"Ingested {result['reports_ingested']} reports")
            except Exception as e:
                st.error(f"Ingestion failed: {e}")

    if "messages" not in st.session_state:
        st.session_state.messages = []

    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.write(msg["content"])
            if msg.get("sources"):
                st.caption("Sources: " + ", ".join(
                    f"Report {s['id']} ({s['location']}, score: {s['score']})"
                    for s in msg["sources"]
                ))

    if prompt := st.chat_input("Ask about disaster incidents..."):
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.write(prompt)

        with st.chat_message("assistant"):
            with st.spinner("Searching incident reports..."):
                try:
                    result = post("/rag/query", {"query": prompt, "top_k": 3})
                    st.write(result["answer"])
                    if result.get("sources"):
                        st.caption("Sources: " + ", ".join(
                            f"Report {s['id']} ({s['location']}, score: {s['score']})"
                            for s in result["sources"]
                        ))
                    st.session_state.messages.append({
                        "role": "assistant",
                        "content": result["answer"],
                        "sources": result.get("sources", []),
                    })
                except Exception as e:
                    st.error(f"AI query failed: {e}")
