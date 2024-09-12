from fastapi import FastAPI
from app.routes import pgtune, health

app = FastAPI()

app.include_router(pgtune.router)
app.include_router(health.router)
