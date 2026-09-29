# Registro de Perritos de la Calle

> **Materia:** Programación Lógica y Funcional  
> **Profesor:** Daniel Varela  
> **Institución:** Instituto Tecnológico de Saltillo  
> **Proyecto 1:** Aplicación web responsiva para el registro y mapeo de perritos callejeros.

---

## 1. Integrantes del Equipo y Roles

| Integrante | Rol | Responsabilidades | Entrega Visible en Repositorio |
| :--- | :--- | :--- | :--- |
| **Luis Palomares** | **Frontend** | Pantallas, formulario, captura/subida de foto, mapa interactivo con pines, validaciones cliente y diseño responsivo para celular. | `Frontend/index.html`, `Frontend/app.js`, `Frontend/style.css`, capturas en README |
| **Ariel Hernández** | **Backend** | API REST (FastAPI), validaciones servidor, almacenamiento seguro de fotos, manejo de errores e idempotencia. | `Back-End/main.py`, `Back-End/rutas.py`, `Back-End/database.py`, `Back-End/archivos.py`, endpoints en README |
| **Santiago Martínez** | **DBA** | Modelo de datos relacional, scripts DDL/DML, catálogos (razas y colores), datos semilla de prueba y respaldos. | `database/schema.sql`, `database/seeds.sql`, Diagrama ER, guía de administración de BDD |

---

## 2. Requisitos Previos (Versiones Exactas)

Este proyecto se ejecuta **estrictamente sin contenedores Docker** (sin `Dockerfile` ni `docker-compose.yml`). Todos los componentes se instalan e inician de forma nativa.

* **Lenguaje Backend:** Python `v3.12` (FastAPI / Uvicorn)
* **Manejador de Base de Datos:** PostgreSQL `v16.x` / `v18.x`
* **Frontend:** HTML5, CSS3, JavaScript ES6+ (Vanilla JS plano, sin Node ni herramientas de build)
* **Control de Versiones:** Git `v2.x`

---

## 3. Manual de Instalación y Configuración: Módulo de Base de Datos

Este manual documenta el procedimiento completo para preparar el entorno de PostgreSQL desde cero, con especial enfoque en Windows (resolviendo problemas comunes de consola y variables de entorno).

### Paso 1: Descarga e Instalación de PostgreSQL

#### Para usuarios de Windows (10/11 64-bit):
1. Ingresar al portal oficial: [postgresql.org/download/windows/](https://www.postgresql.org/download/windows/)
2. Hacer clic en "Download the installer" (certificado por EDB) y seleccionar la versión correspondiente a Windows (x86-64), versión 16+ (ej. 18.x).
3. Ejecutar el archivo instalador `.exe`.
4. Durante el asistente de instalación:
   - **Directorio de instalación y datos:** Mantener las rutas por defecto (ej. `C:\Program Files\PostgreSQL\18\data`).
   - **Componentes:** Seleccionar *PostgreSQL Server* y *Command Line Tools*.
   - **Contraseña:** Definir una contraseña segura para el superusuario `postgres` y guardarla (se ocupará después).
   - **Puerto:** Confirmar el puerto por defecto `5432`.
   - **Locale:** Seleccionar *Default locale* o *Spanish, Mexico*.
5. Al finalizar, desmarcar la casilla de *Stack Builder* y hacer clic en **Finish**. *(El instalador de EDB creará el clúster e iniciará el servicio de Windows automáticamente, por lo que NO es necesario usar `initdb` ni `pg_ctl`)*.

#### En Linux (Ubuntu / Debian):
```bash
sudo apt update && sudo apt install -y postgresql postgresql-contrib
```
*(El servicio se inicia automáticamente).*

#### En macOS (con Homebrew):
```bash
brew install postgresql@16
brew services start postgresql@16
```

---

### Paso 2: Configuración de Variables de Entorno en Windows (Crucial)

Para evitar el error de que *"psql no se reconoce como un comando"*, se debe agregar a las variables del sistema para invocarlo desde cualquier terminal:
1. Presionar la tecla Windows, escribir **"Variables de entorno"** y seleccionar **"Editar las variables de entorno del sistema"**.
2. Hacer clic en el botón inferior **"Variables de entorno..."**.
3. En el apartado inferior (**Variables del sistema**), buscar y seleccionar la variable **Path** y hacer clic en **"Editar..."**.
4. Hacer clic en **"Nuevo"** y pegar la ruta hacia la carpeta `bin` de tu instalación. Ejemplo:
   `C:\Program Files\PostgreSQL\18\bin` *(Cambia el "18" y "PostgreSQL" según tu versión)*.
5. Hacer clic en **Aceptar** en todas las ventanas.
6. **Importante:** Cierra y vuelve a abrir cualquier ventana de terminal (CMD o PowerShell) para que reconozca los cambios.
7. Verifica que funciona ejecutando: `psql --version`

---

### Paso 3: Corrección de Codificación en Consola (Acentos y Caracteres Especiales)

El símbolo del sistema de Windows utiliza por defecto una página de códigos antigua (850 o 1252), lo que produce errores visuales en palabras con acento o eñes (ej. Due±o). Antes de interactuar con la consola de Postgres, cambia la terminal a UTF-8:
```cmd
chcp 65001
```

---

### Paso 4: Clonar el Repositorio

Abre una terminal y clona el proyecto en tu computadora:
```bash
git clone https://github.com/Ariel-Hdz-Gar/Proyecto-ProLog-Unidad1.git
cd Proyecto-ProLog-Unidad1
```

> **💡 Tip para Windows:** Si al ejecutar el comando te sale el error *"git no se reconoce"*, significa que no tienes Git instalado. Puedes instalarlo desde tu consola ejecutando `winget install Git.Git`, o descargarlo directamente desde [git-scm.com/download/win](https://git-scm.com/download/win). Una vez instalado, cierra la terminal y abre una nueva.

---
## 4. Base de Datos: Creación, Esquema y Semillas (DBA)

Abre una terminal (CMD o PowerShell) **en la raíz del repositorio** clonado (`Proyecto-ProLog-Unidad1`) y ejecuta en orden:

### Paso 5: Crear la Base de Datos `perritos_db`

```bash
createdb -U postgres perritos_db
```
*(Si te lo pide, ingresa la contraseña que definiste en la instalación).*

### Paso 6: Cargar el Esquema DDL (Tablas e Índices)

Este comando lee el archivo SQL y crea la estructura de las tablas en la BDD recién creada:
```bash
psql -U postgres -d perritos_db -f database/schema.sql
```

### Paso 7: Cargar Catálogos (Razas, Colores) y Perritos de Prueba

Este comando inserta los 10 colores, 10 razas y 15 registros de prueba con la tabla pivote M:N:
```bash
psql -U postgres -d perritos_db -f database/seeds.sql
```
> **⚠️ Importante para las imágenes de prueba:** El script `seeds.sql` enlaza los 15 perritos de prueba con la imagen de muestra que viene en la carpeta `Images/` del repositorio. Si configuras la variable `RUTA_IMAGENES` hacia una carpeta externa en tu PC (ej. `C:\uploads`), debes copiar manualmente el archivo `.webp` de la carpeta `Images/` hacia tu nueva carpeta externa para que el frontend no muestre errores 404 (imágenes rotas).

### Paso 8: Verificación de Integridad (Opcional)

Para comprobar que todo se cargó correctamente, entra a la base de datos:
```bash
psql -U postgres -d perritos_db
```
Y ejecuta `\dt` para ver el listado de las 4 tablas principales (`razas`, `colores`, `perritos`, `perrito_colores_adicionales`). Escribe `\q` para salir.

---

### Diagrama Entidad-Relación (ERD)

```mermaid
erDiagram
    RAZAS ||--o{ PERRITOS : "tiene"
    COLORES ||--o{ PERRITOS : "es color principal de"
    PERRITOS ||--o{ PERRITO_COLORES_ADICIONALES : "posee"
    COLORES ||--o{ PERRITO_COLORES_ADICIONALES : "figura como adicional en"

    RAZAS {
        int id_raza PK
        varchar nombre UK
    }

    COLORES {
        int id_color PK
        varchar nombre UK
    }

    PERRITOS {
        int id_perrito PK
        varchar idempotency_key UK
        varchar nombre
        int id_raza FK
        int id_color_principal FK
        varchar foto_ruta
        numeric latitud
        numeric longitud
        timestamptz fecha_registro
    }

    PERRITO_COLORES_ADICIONALES {
        int id_perrito PK, FK
        int id_color PK, FK
    }
```

---

### Respaldo y Restauración de la Base de Datos

* **Respaldar base de datos:**
  ```bash
  pg_dump -U postgres -d perritos_db -F c -b -v -f backup_perritos.dump
  ```
* **Restaurar base de datos:**
  ```bash
  pg_restore -U postgres -d perritos_db -v -c backup_perritos.dump
  ```

---

## 5. Variables de Entorno y Configuración (`.env`)

Cree un archivo `.env` en la raíz del proyecto basándose en `.env.example`:

### Tabla de Variables de Entorno

| Variable | Descripción | Ejemplo Local |
| :--- | :--- | :--- |
| `DATABASE_URL` | Cadena de conexión a PostgreSQL | `postgresql://postgres:postgres@localhost:5432/perritos_db` |
| `RUTA_IMAGENES` | **Directorio fuera del código** para guardar las fotos recibidas | `../Images` o `C:/uploads/perritos_fotos` |
| `PORT` | Puerto de ejecución del servidor backend | `8000` |

### Ejemplo `.env.example`

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/perritos_db
RUTA_IMAGENES=../Images
PORT=8000
```

> **REGLA DE SEGURIDAD OBLIGATORIA:** Las fotos subidas por los usuarios **nunca** se almacenan dentro del árbol de código binario (`Frontend/`, `Back-End/`, `static/` o `public/`). Se guardan en el directorio independiente definido por `RUTA_IMAGENES` y se sirven a través del endpoint dedicado `GET /api/imagenes/{nombre_archivo}`.

---

## 6. Cómo Ejecutar el Backend y el Frontend

### Backend (Python FastAPI)

1. Ingresar a la carpeta del backend y crear el entorno virtual:
   ```bash
   cd Back-End
   python3 -m venv venv
   ```
2. Activar el entorno virtual:
   * **Linux/macOS:** `source venv/bin/activate`
   * **Windows (PowerShell):** `.\venv\Scripts\Activate.ps1`
3. Instalar dependencias e iniciar el servidor Uvicorn:
   ```bash
   pip install -r ../requirements.txt
   uvicorn main:app --reload --port 8000
   ```
* **URL Backend:** `http://localhost:8000`

---

### Frontend (HTML/CSS/JS Plano)

El frontend es estático y no requiere herramientas de compilación. 

1. Servir la carpeta `Frontend/` mediante un servidor web local (por ejemplo, la extensión **Live Server** en VS Code o `python3 -m http.server 5500` dentro de la carpeta `Frontend/`).
2. **Importante:** No abrir `index.html` haciendo doble clic directamente como `file://`, ya que los navegadores bloquean la cámara, la geolocalización y las peticiones `fetch()` al backend bajo el protocolo `file://`.
3. Verificar la URL del backend en `Frontend/config.js`:
   ```javascript
   const API_BASE = "http://localhost:8000";
   ```
* **URL Frontend:** `http://localhost:5500` (o la que asignes en Live Server)

---

## 7. Pruebas desde un Dispositivo Móvil en la Misma Red LAN

1. Obtener la dirección IP local de la computadora:
   * **Windows:** `ipconfig` (IPv4 Address, ej. `192.168.1.75`).
   * **Linux / macOS:** `ip a` o `ifconfig`.
2. Actualizar `Frontend/config.js` apuntando a la IP local:
   ```javascript
   const API_BASE = "http://192.168.1.75:8000";
   ```
3. Abrir el navegador del celular (conectado al mismo Wi-Fi) e ingresar a `http://192.168.1.75:5500`.
4. **Permisos de Cámara y Ubicación:**
   Los navegadores exigen contextos seguros (`HTTPS` o `localhost`) para habilitar la API de cámara y geolocalización.
   * **Para probar con HTTPS:** Utilice un túnel como Ngrok (`ngrok http 8000`).
   * **Para probar en local (Android Chrome):** Ingrese a `chrome://flags/#unsafely-treat-insecure-origin-as-secure`, agregue `http://192.168.1.75:5500` y reinicie Chrome.

---

## 8. Lista de Endpoints de la API REST

| Método | Ruta | Descripción | Parámetros / Cuerpo |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | Health check de la API | N/A |
| `GET` | `/api/catalogos` | Retorna los catálogos de razas y colores | JSON con `{ razas: [...], colores: [...] }` |
| `GET` | `/api/imagenes/{nombre_archivo}` | Sirve de forma segura una imagen guardada | `nombre_archivo` (string) |
| `GET` | `/api/perritos` | Lista todos los perritos registrados | Retorna array JSON con datos y rutas de fotos |
| `POST` | `/api/perritos` | Registra un perrito (idempotente) | `multipart/form-data`: `idempotency_key`, `nombre`, `latitud`, `longitud`, `id_color_principal`, `id_raza` (opcional), `colores_adicionales` (0-2 extra), `foto` |

---

## 9. Capturas de Pantalla

<p collections="carousel" align="center">
  <img width="500" alt="Formulario y Cámara en Celular" src="https://github.com/user-attachments/assets/f11eb329-5f22-49ce-afcf-c440398c868a" />
  <img width="500" alt="Mapa Interactivo con Pines" src="https://github.com/user-attachments/assets/c66dc925-6f85-4644-8348-12979934a9bc" />
  <img width="500" alt="Lista de Registros y Miniaturas" src="https://github.com/user-attachments/assets/7acf08bc-1fd6-465d-8f91-82dc023740c3" />
  <img width="500" alt="Detalle del Registro de Perrito" src="https://github.com/user-attachments/assets/95ea49c5-9fd0-4fca-9375-b72cd65babbc" />
</p>

---

## 10. Matriz de Resolución de Problemas Comunes (Troubleshooting)

| Problema / Error | Causa Probable | Solución |
| :--- | :--- | :--- |
| **"No se pudo conectar con el servidor"** | El backend no está ejecutándose o `API_BASE` en `config.js` tiene la IP incorrecta. | Iniciar Uvicorn (`uvicorn main:app --reload --port 8000`) y verificar la URL en `Frontend/config.js`. |
| **`ModuleNotFoundError: psycopg`** | No se instalaron las dependencias del archivo `requirements.txt`. | Ejecutar `pip install -r requirements.txt` dentro del entorno virtual. |
| **Falla la autenticación de Postgres** | La contraseña en `DATABASE_URL` no coincide con la del usuario `postgres`. | Corregir la contraseña en el archivo `.env`. |
| **No sale la opción de tomar foto (solo "Seleccionar archivo")** | El atributo `capture="environment"` actúa como cámara activa en celulares; en computadoras de escritorio se abre el explorador de archivos. | Probar el formulario desde un teléfono inteligente real. |
| **La cámara/ubicación no piden permiso en el celular** | Los navegadores móviles bloquean el acceso al hardware si el sitio se carga por HTTP plano sin ser `localhost`. | Utilizar un túnel HTTPS (ej. Ngrok) o configurar la excepción en `chrome://flags`. |
| **HTTP 400 "Falta la foto" o "Formato de imagen inválido"** | El formulario envió un archivo vacío o con extensión no permitida (solo JPG, PNG, WEBP). | Seleccionar una fotografía válida en los formatos soportados. |

---

## 11. Sección Paradigmas de Programación

### 1. Paradigma Declarativo
* **Consultas SQL en Base de Datos (`database/schema.sql` y `Back-End/rutas.py`):**
  Las consultas de filtrado, ordenamiento y agregación son resueltas internamente por el manejador PostgreSQL mediante SQL declarativo. Se evita extraer registros masivos para iterar con ciclos manuales en Python.
* **Interfaz de Usuario (HTML5 / CSS3):**
  `Frontend/index.html` y `Frontend/style.css` describen qué elementos visuales y reglas de diseño deben mostrarse, delegando al motor del navegador la renderización.

### 2. Paradigma Imperativo y Orientado a Objetos
* **Controladores Backend (FastAPI / SQLAlchemy):**
  En `Back-End/rutas.py` y `Back-End/archivos.py` se utiliza el paradigma imperativo para el control de flujo procedural, manejo de excepciones de E/S en disco, validaciones de tipos de archivo y respuestas HTTP.

### 3. Transformación de Datos en Estilo Funcional (Sin Mutación ni Ciclos Explícitos)
* **Backend (`Back-End/rutas.py`):**
  Transformación declarativa de tuplas de base de datos a diccionarios JSON mediante la función de orden superior `map()` y `lambda`:
  ```python
  lista_razas = list(map(lambda r: {"id": r[0], "nombre": r[1]}, razas))
  lista_colores = list(map(lambda c: {"id": c[0], "nombre": c[1]}, colores))
  ```
* **Frontend (`Frontend/app.js`):**
  En el cliente, funciones como `cargarCatalogos()`, `pintarLista()` y `pintarMapaGeneral()` transforman los arreglos de perritos y catálogos utilizando `.map()` y `.filter()` sin mutar la estructura original ni emplear ciclos `for`/`while` explícitos:
  ```javascript
  catalogoRazas.map(r => `<option value="${r.id}">${r.nombre}</option>`).join("")
  ```

### 4. Idempotencia del Registro de Perritos
* **Problema:** En zonas con mala cobertura de red móvil, el usuario puede presionar el botón "Enviar" múltiples veces o el cliente puede reintentar el envío, provocando duplicados.
* **Solución:**
  1. Al abrir el formulario en `Frontend/app.js`, se genera una clave única con `crypto.randomUUID()`.
  2. La clave se envía en el cuerpo de la petición `POST /api/perritos` (`idempotency_key`).
  3. En `Back-End/rutas.py`, antes de insertar, se consulta si la clave existe en PostgreSQL:
     ```python
     check_query = text("SELECT id_perrito FROM perritos WHERE idempotency_key = :key")
     existente = db.execute(check_query, {"key": idempotency_key}).fetchone()
     if existente:
         return {"mensaje": "Registro procesado previamente", "id_perrito": existente[0]}
     ```
  4. La base de datos respalda la regla con una restricción `UNIQUE(idempotency_key)`. Ante un envío duplicado, el backend devuelve el registro original sin duplicarlo ni responder con error.
* **Prueba del Doble Envío en Vivo:**
  Ejecute la misma petición `curl` dos veces consecutivas enviando la misma clave:
  ```bash
  curl -X POST http://localhost:8000/api/perritos \
    -F "idempotency_key=test-uuid-999" \
    -F "nombre=Firulais Test" \
    -F "id_color_principal=1" \
    -F "latitud=25.42" -F "longitud=-101.00" \
    -F "foto=@foto_prueba.jpg"
  ```
  La segunda ejecución devolverá `{"mensaje": "Registro procesado previamente", "id_perrito": ...}` conservando un único registro en la base de datos.

---

## 12. Sección Despliegue en Producción (Sin Docker)

La aplicación se encuentra actualmente **publicada y operativa en una instancia EC2 de AWS con Ubuntu Server**.

### Arquitectura de Producción

1. **Uvicorn + Systemd:**
   La API de FastAPI se ejecuta en el puerto `8000` y se administra mediante un servicio nativo de Linux (`systemd`). Esto garantiza que el proceso backend corra permanentemente en segundo plano y se reinicie automáticamente ante reinicios del servidor.
   * **URL Pública del Backend:** `http://100.52.230.125:8000`

2. **Conexión Frontend - Backend:**
   El frontend está configurado en `Frontend/config.js` para consumir los datos de la instancia EC2 (`http://100.52.230.125:8000`).

3. **Acceso al Hardware (Cámara y GPS):**
   Dado que el servicio opera sobre HTTP y los navegadores bloquean el acceso al GPS y cámara por falta de HTTPS en IPs remotas, la demostración del frontend se ejecuta desde la máquina local (`localhost`), permitiendo el uso completo del hardware (Cámara/GPS) mientras interactúa en tiempo real con la base de datos de producción en AWS.
