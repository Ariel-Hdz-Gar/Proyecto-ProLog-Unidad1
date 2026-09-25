-- Eliminación limpia si se requiere reiniciar
DROP TABLE IF EXISTS perrito_colores_adicionales CASCADE;
DROP TABLE IF EXISTS perritos CASCADE;
DROP TABLE IF EXISTS colores CASCADE;
DROP TABLE IF EXISTS razas CASCADE;

-- 1. Catálogo de Razas
CREATE TABLE razas (
    id_raza SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE
);

-- 2. Catálogo de Colores
CREATE TABLE colores (
    id_color SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

-- 3. Tabla Principal de Perritos
CREATE TABLE perritos (
    id_perrito SERIAL PRIMARY KEY,
    idempotency_key VARCHAR(64) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    id_raza INTEGER NULL REFERENCES razas(id_raza) ON DELETE RESTRICT,
    id_color_principal INTEGER NOT NULL REFERENCES colores(id_color) ON DELETE RESTRICT,
    foto_ruta VARCHAR(255) NOT NULL,
    latitud NUMERIC(10, 8) NOT NULL,
    longitud NUMERIC(11, 8) NOT NULL,
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_nombre_no_vacio CHECK (length(trim(nombre)) > 0)
);

-- 4. Tabla pivote: Colores adicionales (de 0 a 2 colores)
CREATE TABLE perrito_colores_adicionales (
    id_perrito INTEGER NOT NULL REFERENCES perritos(id_perrito) ON DELETE CASCADE,
    id_color INTEGER NOT NULL REFERENCES colores(id_color) ON DELETE RESTRICT,
    PRIMARY KEY (id_perrito, id_color)
);

-- Índices para optimización de consultas
CREATE INDEX idx_perritos_idempotency ON perritos(idempotency_key);
CREATE INDEX idx_perritos_coords ON perritos(latitud, longitud);