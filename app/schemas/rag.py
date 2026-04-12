from pydantic import BaseModel
from typing import Optional


class RAGQuery(BaseModel):
    query: str
    top_k: int = 3
    filters: Optional[dict] = None


class RAGSource(BaseModel):
    id: Optional[int] = None
    location: Optional[str] = None
    score: Optional[float] = None


class RAGResponse(BaseModel):
    answer: str
    sources: list[RAGSource]
    status: str


class IngestResponse(BaseModel):
    status: str
    reports_ingested: int
