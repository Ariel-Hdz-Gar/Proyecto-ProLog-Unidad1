FROM python:3.11-slim
WORKDIR /app

# Copia tu HTML, CSS y JS al contenedor
COPY . /app

EXPOSE 3000

# Arranca el servidor estático
CMD ["python", "-m", "http.server", "3000"]