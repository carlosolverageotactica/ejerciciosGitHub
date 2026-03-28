-- =============================================================
-- 02_schema.sql
-- Creación del esquema principal de la base de datos geoespacial
-- =============================================================

-- Esquema principal para entidades del sistema
CREATE SCHEMA IF NOT EXISTS geo;

-- Esquema para datos de referencia / catálogos
CREATE SCHEMA IF NOT EXISTS catalogo;

-- Esquema para auditoría y logs
CREATE SCHEMA IF NOT EXISTS auditoria;

-- Establecer search_path por defecto
ALTER DATABASE geodb SET search_path TO geo, catalogo, auditoria, public;

-- =============================================================
-- Catálogo de categorías de POI (debe crearse antes de geo.puntos_interes)
-- =============================================================
CREATE TABLE IF NOT EXISTS catalogo.categorias_poi (
    id          SERIAL PRIMARY KEY,
    codigo      VARCHAR(50) UNIQUE NOT NULL,
    nombre      VARCHAR(255) NOT NULL,
    descripcion TEXT,
    icono       VARCHAR(255),
    color       VARCHAR(7) DEFAULT '#000000',
    activo      BOOLEAN NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE catalogo.categorias_poi IS 'Catálogo de categorías para puntos de interés';

-- =============================================================
-- Tabla de regiones / zonas geográficas
-- =============================================================
CREATE TABLE IF NOT EXISTS geo.regiones (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre      VARCHAR(255) NOT NULL,
    codigo      VARCHAR(50) UNIQUE,
    descripcion TEXT,
    geom        GEOMETRY(MULTIPOLYGON, 4326),
    activo      BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_regiones_geom
    ON geo.regiones USING GIST (geom);

COMMENT ON TABLE geo.regiones IS 'Regiones o zonas geográficas del sistema';

-- =============================================================
-- Tabla de puntos de interés (POI)
-- =============================================================
CREATE TABLE IF NOT EXISTS geo.puntos_interes (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre      VARCHAR(255) NOT NULL,
    categoria   VARCHAR(100) REFERENCES catalogo.categorias_poi(codigo) ON UPDATE CASCADE,
    descripcion TEXT,
    geom        GEOMETRY(POINT, 4326) NOT NULL,
    metadata    JSONB,
    activo      BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_puntos_interes_geom
    ON geo.puntos_interes USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_puntos_interes_categoria
    ON geo.puntos_interes (categoria);

CREATE INDEX IF NOT EXISTS idx_puntos_interes_metadata
    ON geo.puntos_interes USING GIN (metadata);

COMMENT ON TABLE geo.puntos_interes IS 'Puntos de interés georreferenciados';

-- =============================================================
-- Tabla de rutas / trazados lineales
-- =============================================================
CREATE TABLE IF NOT EXISTS geo.rutas (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre      VARCHAR(255) NOT NULL,
    tipo        VARCHAR(100),
    descripcion TEXT,
    geom        GEOMETRY(MULTILINESTRING, 4326),
    longitud_m  DOUBLE PRECISION GENERATED ALWAYS AS (ST_Length(geom::GEOGRAPHY)) STORED,
    activo      BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rutas_geom
    ON geo.rutas USING GIST (geom);

COMMENT ON TABLE geo.rutas IS 'Rutas y trazados lineales del sistema';

-- =============================================================
-- Tabla de auditoría (log de cambios)
-- =============================================================
CREATE TABLE IF NOT EXISTS auditoria.log_cambios (
    id           BIGSERIAL PRIMARY KEY,
    tabla        VARCHAR(255) NOT NULL,
    esquema      VARCHAR(255) NOT NULL,
    operacion    VARCHAR(10) NOT NULL CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    registro_id  TEXT,
    datos_antes  JSONB,
    datos_despues JSONB,
    usuario_db   VARCHAR(255) DEFAULT current_user,
    timestamp    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_log_cambios_tabla
    ON auditoria.log_cambios (esquema, tabla);

CREATE INDEX IF NOT EXISTS idx_log_cambios_timestamp
    ON auditoria.log_cambios (timestamp DESC);

COMMENT ON TABLE auditoria.log_cambios IS 'Registro de auditoría para todos los cambios en la base de datos';
