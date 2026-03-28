-- =============================================================
-- 01_extensions.sql
-- Habilitación de extensiones PostGIS y utilitarias
-- =============================================================

-- PostGIS: soporte de geometría y geografía espacial
CREATE EXTENSION IF NOT EXISTS postgis;

-- PostGIS Topology: soporte de topología vectorial
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- PostGIS Raster: soporte de datos raster
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- fuzzystrmatch: funciones de similitud de cadenas (útil con geocodificación)
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- PostGIS Tiger Geocoder (requiere fuzzystrmatch)
-- CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;

-- uuid-ossp: generación de UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- pgcrypto: funciones criptográficas
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Verificar instalación
SELECT postgis_full_version();
