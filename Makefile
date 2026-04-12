.PHONY: db-reset seed api streamlit dev install

db-reset:
	supabase db reset

seed:
	supabase db reset

api:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

streamlit:
	streamlit run streamlit_app/app.py

dev:
	supabase db reset && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

install:
	pip install -r requirements.txt
	pip install -r requirements-streamlit.txt
