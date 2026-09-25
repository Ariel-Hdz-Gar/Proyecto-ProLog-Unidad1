import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Se leen las variables de entorno para no subir contraseñas al repositorio,
# cumpliendo con la regla de usar .env y .gitignore
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "Ark_games554")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "perritos_db")

# URL de conexión a PostgreSQL (requiere instalar psycopg2-binary)
DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Creación del motor de la base de datos
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()