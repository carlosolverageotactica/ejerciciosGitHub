-- =============================================================
-- 03_functions.sql
-- Funciones y triggers de utilidad
-- =============================================================

-- =============================================================
-- Función: actualizar timestamp de modificación
-- =============================================================
CREATE OR REPLACE FUNCTION public.fn_actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.fn_actualizar_timestamp() IS
    'Actualiza el campo actualizado_en al momento de un UPDATE';

-- Trigger en geo.regiones
CREATE OR REPLACE TRIGGER trg_regiones_actualizado_en
    BEFORE UPDATE ON geo.regiones
    FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_timestamp();

-- Trigger en geo.puntos_interes
CREATE OR REPLACE TRIGGER trg_puntos_interes_actualizado_en
    BEFORE UPDATE ON geo.puntos_interes
    FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_timestamp();

-- Trigger en geo.rutas
CREATE OR REPLACE TRIGGER trg_rutas_actualizado_en
    BEFORE UPDATE ON geo.rutas
    FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_timestamp();

-- =============================================================
-- Función: registrar auditoría
-- =============================================================
CREATE OR REPLACE FUNCTION auditoria.fn_registrar_cambio()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria.log_cambios
            (tabla, esquema, operacion, registro_id, datos_despues)
        VALUES
            (TG_TABLE_NAME, TG_TABLE_SCHEMA, TG_OP, NEW.id::TEXT, row_to_json(NEW)::JSONB);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria.log_cambios
            (tabla, esquema, operacion, registro_id, datos_antes, datos_despues)
        VALUES
            (TG_TABLE_NAME, TG_TABLE_SCHEMA, TG_OP, NEW.id::TEXT,
             row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria.log_cambios
            (tabla, esquema, operacion, registro_id, datos_antes)
        VALUES
            (TG_TABLE_NAME, TG_TABLE_SCHEMA, TG_OP, OLD.id::TEXT, row_to_json(OLD)::JSONB);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION auditoria.fn_registrar_cambio() IS
    'Registra todos los cambios DML en la tabla de auditoría';

-- Triggers de auditoría
CREATE OR REPLACE TRIGGER trg_audit_regiones
    AFTER INSERT OR UPDATE OR DELETE ON geo.regiones
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_registrar_cambio();

CREATE OR REPLACE TRIGGER trg_audit_puntos_interes
    AFTER INSERT OR UPDATE OR DELETE ON geo.puntos_interes
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_registrar_cambio();

CREATE OR REPLACE TRIGGER trg_audit_rutas
    AFTER INSERT OR UPDATE OR DELETE ON geo.rutas
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_registrar_cambio();

-- =============================================================
-- Función: buscar POIs dentro de un radio (metros)
-- =============================================================
CREATE OR REPLACE FUNCTION geo.fn_poi_en_radio(
    p_longitud  DOUBLE PRECISION,
    p_latitud   DOUBLE PRECISION,
    p_radio_m   DOUBLE PRECISION,
    p_categoria VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (
    id          UUID,
    nombre      VARCHAR,
    categoria   VARCHAR,
    descripcion TEXT,
    distancia_m DOUBLE PRECISION,
    geom        GEOMETRY
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        poi.id,
        poi.nombre,
        poi.categoria,
        poi.descripcion,
        ST_Distance(
            poi.geom::GEOGRAPHY,
            ST_SetSRID(ST_MakePoint(p_longitud, p_latitud), 4326)::GEOGRAPHY
        ) AS distancia_m,
        poi.geom
    FROM geo.puntos_interes poi
    WHERE
        poi.activo = TRUE
        AND ST_DWithin(
            poi.geom::GEOGRAPHY,
            ST_SetSRID(ST_MakePoint(p_longitud, p_latitud), 4326)::GEOGRAPHY,
            p_radio_m
        )
        AND (p_categoria IS NULL OR poi.categoria = p_categoria)
    ORDER BY distancia_m ASC;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION geo.fn_poi_en_radio IS
    'Devuelve puntos de interés dentro de un radio dado (en metros) desde una coordenada';
