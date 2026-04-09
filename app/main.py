from fastapi import FastAPI
from app.routers import disasters, organizations, beneficiaries, programs

app = FastAPI(title="DisasterLink API", version="1.0.0")

app.include_router(disasters.router)
app.include_router(organizations.router)
app.include_router(beneficiaries.router)
app.include_router(programs.router)

@app.get("/")
def root():
    return {"message": "DisasterLink API is running"}
