import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())

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

ruta_imagenes = os.getenv("RUTA_IMAGENES", "C:/uploads/perritos")
# Asegurar que el directorio exista para que FastAPI no arroje error al arrancar
os.makedirs(ruta_imagenes, exist_ok=True)
app.mount("/api/imagenes", StaticFiles(directory=ruta_imagenes), name="imagenes")

#app.mount("/", StaticFiles(directory="/home/ubuntu/Proyecto-ProLog-Unidad1/Frontend", html=True), name="Frontend")