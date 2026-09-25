from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from rutas import router as perritos_router

app = FastAPI(title="API Registro de Perritos")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(perritos_router)

@app.get("/")
def home():
    return {"mensaje": "Api Funcional"}