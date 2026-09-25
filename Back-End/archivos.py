import os
import uuid
import shutil
from fastapi import UploadFile, HTTPException

RUTA_IMAGENES = os.getenv("RUTA_IMAGENES", "C:/Users/gark0/Downloads/imagenes_perritos")

def es_imagen_valida(content_type: str) -> bool:
    formatos_permitidos = ["image/jpeg", "image/png", "image/webp"]
    return content_type in formatos_permitidos

def guardar_foto(foto: UploadFile) -> str:
    if not es_imagen_valida(foto.content_type):
        raise HTTPException(status_code=400, detail="Formato de imagen inválido. Solo JPG, PNG o WEBP.")

    extension = foto.filename.split(".")[-1].lower()
    
    nombre_seguro = f"{uuid.uuid4().hex}.{extension}"
    ruta_completa = os.path.join(RUTA_IMAGENES, nombre_seguro)
    
    os.makedirs(RUTA_IMAGENES, exist_ok=True)
    
    try:
        with open(ruta_completa, "wb") as buffer:
            shutil.copyfileobj(foto.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error interno al guardar la imagen.")
        
    return nombre_seguro