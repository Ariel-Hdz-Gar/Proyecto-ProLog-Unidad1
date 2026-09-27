import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
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

ruta_imagenes = os.getenv("RUTA_IMAGENES", "/tmp/perritos_fotos")
app.mount("/api/imagenes", StaticFiles(directory=ruta_imagenes), name="imagenes")

@app.get("/")
def home():
    return {"mensaje": "Api Funcional"}

app.mount("/", StaticFiles(directory="Frontend", html=True), name="Frontend")