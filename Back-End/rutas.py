import os
from fastapi import APIRouter, Depends, HTTPException, Form, UploadFile, File
from fastapi.responses import FileResponse
from fastapi import HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import text
from database import get_db
import archivos

router = APIRouter()

@router.get("/api/imagenes/{nombre_archivo}")
def obtener_imagen(nombre_archivo: str):
    ruta_completa = os.path.join(archivos.RUTA_IMAGENES, nombre_archivo)
    if not os.path.exists(ruta_completa):
        raise HTTPException(status_code=404, detail="Imagen no encontrada")
        
    return FileResponse(ruta_completa)

@router.get("/api/catalogos")
def obtener_catalogos(db: Session = Depends(get_db)):
    razas = db.execute(text("SELECT id_raza, nombre FROM razas ORDER BY id_raza")).fetchall()
    colores = db.execute(text("SELECT id_color, nombre FROM colores ORDER BY id_color")).fetchall()
    lista_razas = list(map(lambda r: {"id": r[0], "nombre": r[1]}, razas))
    lista_colores = list(map(lambda c: {"id": c[0], "nombre": c[1]}, colores))
    return {
        "razas": lista_razas,
        "colores": lista_colores
    }

@router.post("/api/perritos")
def registrar_perrito(
    idempotency_key: str = Form(...),
    nombre: str = Form(...),
    latitud: float = Form(...),
    longitud: float = Form(...),
    id_color_principal: int = Form(...),
    id_raza: Optional[int] = Form(None),
    colores_adicionales: List[int] = Form(default=[]), # 0 a 2 colores extra
    foto: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # 1. Verificar idempotencia
    check_query = text("SELECT id_perrito FROM perritos WHERE idempotency_key = :key")
    existente = db.execute(check_query, {"key": idempotency_key}).fetchone()
    if existente:
        return {"mensaje": "Registro procesado previamente", "id_perrito": existente[0]}

    # 2. Validar y guardar la imagen
    if not archivos.es_imagen_valida(foto.content_type):
        raise HTTPException(status_code=400, detail="Formato de imagen inválido. Solo JPG, PNG o WEBP.")
    
    nombre_seguro = archivos.guardar_foto(foto)

    # 3. Insertar perrito
    insert_perrito = text("""
        INSERT INTO perritos (idempotency_key, nombre, id_raza, id_color_principal, foto_ruta, latitud, longitud)
        VALUES (:key, :nombre, :raza, :color, :foto, :lat, :lon)
        RETURNING id_perrito
    """)
    
    nuevo_id = db.execute(insert_perrito, {
        "key": idempotency_key, 
        "nombre": nombre, 
        "raza": id_raza, 
        "color": id_color_principal, 
        "foto": nombre_seguro, # Variable corregida
        "lat": latitud, 
        "lon": longitud
    }).scalar()

    # 4. Insertar colores adicionales
    if colores_adicionales:
        insert_colores = text("INSERT INTO perrito_colores_adicionales (id_perrito, id_color) VALUES (:p_id, :c_id)")
        for color_id in colores_adicionales[:2]: # Max 2 colores adicionales
            db.execute(insert_colores, {"p_id": nuevo_id, "c_id": color_id})

    db.commit()
    
    return {
        "mensaje": "Perrito registrado exitosamente", 
        "id_perrito": nuevo_id,
        "foto_guardada": nombre_seguro
    }