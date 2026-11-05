FROM python:3.11-slim
WORKDIR /app

# Copia todo el código de tu backend a la imagen
COPY . /app

# Instala las dependencias necesarias para tu API y PostgreSQL
RUN pip install --no-cache-dir fastapi uvicorn sqlalchemy psycopg2-binary psycopg psycopg-binary python-dotenv python-multipart

EXPOSE 8000

# Arranca el servidor FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]