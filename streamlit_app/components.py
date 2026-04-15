import streamlit as st
import pandas as pd


def stat_card(label, value, icon="📊"):
    st.metric(label=label, value=value)


def data_table(df: pd.DataFrame, title: str = None):
    if title:
        st.subheader(title)
    if df.empty:
        st.info("No data available.")
    else:
        st.dataframe(df, use_container_width=True)


def severity_color(severity):
    colors = {
        "Info": "🔵",
        "Warning": "🟡",
        "Critical": "🔴",
    }
    return colors.get(severity, "⚪")


def format_date(date_str):
    if not date_str:
        return "—"
    return str(date_str)[:10]


def severity_to_color(severity: str) -> list[int]:
    """Map disaster severity to RGBA color tuple."""
    colors = {
        "Critical": [220, 38, 38, 200],    # red
        "High": [234, 88, 12, 200],        # orange
        "Medium": [202, 138, 4, 200],      # yellow
        "Low": [22, 163, 74, 200],         # green
    }
    return colors.get(severity, [107, 114, 128, 200])  # gray fallback
