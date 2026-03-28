-- =============================================================
-- 04_seed.sql
-- Datos iniciales / de ejemplo
-- =============================================================

-- Categorías de POI
INSERT INTO catalogo.categorias_poi (codigo, nombre, descripcion, color) VALUES
    ('COMERCIO',    'Comercio',         'Tiendas, mercados y centros comerciales', '#FF6B35'),
    ('SALUD',       'Salud',            'Hospitales, clínicas y farmacias',        '#E63946'),
    ('EDUCACION',   'Educación',        'Escuelas, colegios y universidades',      '#457B9D'),
    ('TRANSPORTE',  'Transporte',       'Paradas, estaciones y terminales',        '#2A9D8F'),
    ('RECREACION',  'Recreación',       'Parques, plazas y áreas verdes',          '#52B788'),
    ('GOBIERNO',    'Gobierno',         'Oficinas y servicios gubernamentales',    '#6A4C93'),
    ('TURISMO',     'Turismo',          'Sitios turísticos y culturales',          '#F4A261')
ON CONFLICT (codigo) DO NOTHING;

-- Región de ejemplo (bounding box aproximado de Ciudad de México)
INSERT INTO geo.regiones (nombre, codigo, descripcion, geom) VALUES (
    'Ciudad de México',
    'CDMX',
    'Capital de México y región metropolitana',
    ST_SetSRID(
        ST_GeomFromText(
            'MULTIPOLYGON(((-99.3653 19.0489, -98.9404 19.0489, -98.9404 19.5930, -99.3653 19.5930, -99.3653 19.0489)))'
        ),
        4326
    )
) ON CONFLICT (codigo) DO NOTHING;

-- Puntos de interés de ejemplo
INSERT INTO geo.puntos_interes (nombre, categoria, descripcion, geom, metadata) VALUES
    (
        'Zócalo - Plaza de la Constitución',
        'TURISMO',
        'La plaza principal de la Ciudad de México',
        ST_SetSRID(ST_MakePoint(-99.1332, 19.4326), 4326),
        '{"horario": "24 horas", "acceso": "libre"}'::JSONB
    ),
    (
        'Bosque de Chapultepec',
        'RECREACION',
        'Parque urbano más grande de la Ciudad de México',
        ST_SetSRID(ST_MakePoint(-99.1877, 19.4200), 4326),
        '{"horario": "05:00-16:30", "acceso": "libre", "secciones": 3}'::JSONB
    ),
    (
        'Aeropuerto Internacional Felipe Ángeles',
        'TRANSPORTE',
        'Aeropuerto internacional al norte de la Ciudad de México',
        ST_SetSRID(ST_MakePoint(-99.1143, 19.7457), 4326),
        '{"tipo": "aeropuerto", "iata": "NLU"}'::JSONB
    )
ON CONFLICT DO NOTHING;
