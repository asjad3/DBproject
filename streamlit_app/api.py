import os
import requests
from dotenv import load_dotenv

load_dotenv()

API_BASE = os.getenv("STREAMLIT_API_BASE_URL", "http://localhost:8000")
API_KEY = os.getenv("API_KEY", "")

def _headers():
    h = {"Content-Type": "application/json"}
    if API_KEY:
        h["X-API-Key"] = API_KEY
    return h

def _url(path):
    return f"{API_BASE}{path}"

def get(path, params=None):
    r = requests.get(_url(path), headers=_headers(), params=params, timeout=30)
    r.raise_for_status()
    return r.json()

def post(path, data=None):
    r = requests.post(_url(path), headers=_headers(), json=data, timeout=60)
    r.raise_for_status()
    return r.json()
