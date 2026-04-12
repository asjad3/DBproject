from pydantic import BaseModel, ConfigDict


class RAGQuery(BaseModel):
    query: str
    top_k: int = 3
    filters: dict | None = None


class RAGSource(BaseModel):
    id: int | None = None
    location: str | None = None
    score: float | None = None

    model_config = ConfigDict(from_attributes=True)


class RAGResponse(BaseModel):
    answer: str
    sources: list[RAGSource]
    status: str


class IngestResponse(BaseModel):
    status: str
    reports_ingested: int

    model_config = ConfigDict(from_attributes=True)
