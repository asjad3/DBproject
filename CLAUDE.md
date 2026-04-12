# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**DisasterLink** is a disaster management and relief coordination system for Pakistan. It combines a PostgreSQL database (managed via Supabase), a FastAPI backend, and a RAG-powered AI assistant for querying incident reports.

## Architecture

### Database Layer (`supabase/migrations/`)

The schema is a PostgreSQL design with 17 tables covering disaster management, relief operations, organizations, beneficiaries, and monitoring. Key features:
- ENUM types for status/severity fields
- Two triggers: T1 (fulfillment status auto-update) and T2 (disaster severity audit)
- Stored procedures: `sp_register_org_for_program` (SP1), `sp_requirement_gap_report` (SP2)
- Five analytical views: `v_active_program_summary`, `v_org_fulfillment_leaderboard`, `v_beneficiary_aid_history`, `v_requirement_gap`, `v_disaster_impact_summary`
- Run migrations with: `supabase db reset`

### FastAPI Backend (`app/`)

Python FastAPI app with connection-pooled MySQL (via `mysql-connector-python`). Structure:
- `app/main.py` — FastAPI entry point, includes 4 routers
- `app/database.py` — MySQL connection pool (`get_connection()`)
- `app/routers/` — API routers: `disasters.py`, `organizations.py`, `beneficiaries.py`, `programs.py` (currently stubs with prefix/tags only)
- `app/schemas/` — Pydantic schemas (empty `__init__.py`)
- `app/models/` — Data models (empty `__init__.py`)

Start the dev server: `uvicorn app.main:app --reload`

### RAG Pipeline (`rag/`)

A retrieval-augmented generation pipeline for querying incident reports semantically:
- `rag/db_connector.py` — Fetches reports from Supabase, PostgreSQL, or mock data (controlled by `DB_TYPE` env var)
- `rag/embed_pipeline.py` — Embeds reports into ChromaDB using `sentence-transformers/all-MiniLM-L6-v2`
- `rag/retriever.py` — Semantic search against ChromaDB with optional metadata filters
- `rag/generator.py` — Generates responses via Google Gemini (`gemini-3-flash-preview`) with source citations
- `rag/mock_data.py` — 8 mock incident reports for testing without a database

Run individual components:
- `python rag/db_connector.py` — fetch and print reports
- `python rag/embed_pipeline.py` — ingest reports into ChromaDB
- `python rag/retriever.py` — run a test retrieval query
- `python rag/generator.py` — run the full RAG pipeline end-to-end

## Common Commands

```bash
# Database
supabase db reset                          # Apply all migrations

# Backend
uvicorn app.main:app --reload              # Start FastAPI dev server

# RAG Pipeline
python rag/db_connector.py                 # Test data fetching
python rag/embed_pipeline.py               # Embed reports into vector DB
python rag/retriever.py                    # Test semantic retrieval
python rag/generator.py                    # Full RAG end-to-end test

# Python dependencies
pip install -r requirements.txt            # Install all dependencies
```

## Environment Variables

See `.env.example` for required variables:
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` — MySQL connection
- `SUPABASE_URL`, `SUPABASE_KEY` — Supabase client
- `PG_HOST`, `PG_PORT`, `PG_USER`, `PG_PASSWORD`, `PG_DATABASE` — PostgreSQL connection
- `GEMINI_API_KEY` — Google Gemini API key
- `DB_TYPE` — Data source for RAG: `supabase`, `postgres`, or `mysql` (default: `postgres`)
- `CHROMA_PATH` — Local path for ChromaDB vector store (default: `./chroma_db`)

## Key Design Decisions

- The FastAPI app uses MySQL (`mysql-connector-python`) while the RAG pipeline supports PostgreSQL/Supabase — these are separate data sources
- The RAG pipeline uses local ChromaDB (not a hosted vector store) for embeddings
- Incident reports from `incident_report` table are the sole source material for the RAG AI assistant
