# Base de Datos Geoespacial — PostgreSQL + PostGIS

Este módulo contiene la configuración y los scripts de inicialización de la base de datos **PostgreSQL 15 con PostGIS 3.4**, que actúa como el núcleo del sistema.

---

## Tecnologías

| Componente | Versión | Descripción |
|---|---|---|
| PostgreSQL | 15 | Motor de base de datos relacional |
| PostGIS | 3.4 | Extensión geoespacial para PostgreSQL |
| pgAdmin 4 | latest | Interfaz gráfica de administración |

---

## Estructura del directorio

```
database/
└── init/
    ├── 01_extensions.sql   # Extensiones: postgis, uuid-ossp, pgcrypto...
    ├── 02_schema.sql       # Esquemas, tablas e índices espaciales
    ├── 03_functions.sql    # Funciones PL/pgSQL y triggers
    └── 04_seed.sql         # Datos iniciales / catálogos
docker-compose.yml          # Orquestación de servicios
.env.example                # Variables de entorno de ejemplo
```

---

## Esquemas de la base de datos

| Esquema | Descripción |
|---|---|
| `geo` | Entidades espaciales principales (regiones, POIs, rutas) |
| `catalogo` | Tablas de referencia y catálogos |
| `auditoria` | Registro de todos los cambios DML |

### Tablas principales

- **`geo.regiones`** — Polígonos de zonas o regiones geográficas  
- **`geo.puntos_interes`** — Puntos de interés georreferenciados (POINT)  
- **`geo.rutas`** — Trazados lineales y rutas (MULTILINESTRING)  
- **`catalogo.categorias_poi`** — Catálogo de categorías para POIs  
- **`auditoria.log_cambios`** — Log de auditoría de cambios en la BD  

---

## Puesta en marcha

### 1. Configurar variables de entorno

```bash
cp .env.example .env
# Editar .env con tus credenciales
```

### 2. Levantar los servicios

```bash
docker compose up -d
```

### 3. Verificar el estado

```bash
docker compose ps
docker compose logs postgis
```

### 4. Acceder a pgAdmin

Abrir el navegador en [http://localhost:5050](http://localhost:5050)

- **Email:** `admin@admin.com` (o el valor de `PGADMIN_EMAIL`)
- **Password:** `admin` (o el valor de `PGADMIN_PASSWORD`)

### 5. Conectarse directamente con psql

```bash
docker exec -it postgis_db psql -U geouser -d geodb
```

---

## Funciones espaciales disponibles

### `geo.fn_poi_en_radio`

Devuelve los puntos de interés dentro de un radio en metros desde una coordenada dada.

```sql
SELECT * FROM geo.fn_poi_en_radio(
    p_longitud  => -99.1332,   -- longitud del centro
    p_latitud   => 19.4326,    -- latitud del centro
    p_radio_m   => 5000,       -- radio en metros
    p_categoria => 'TURISMO'   -- (opcional) filtrar por categoría
);
```

---

## Índices espaciales

Todos los campos `geom` cuentan con índices **GIST** para consultas espaciales eficientes:

```sql
-- Ejemplo: intersección
SELECT nombre FROM geo.regiones
WHERE ST_Intersects(geom, ST_MakeEnvelope(-99.2, 19.3, -99.0, 19.5, 4326));

-- Ejemplo: distancia
SELECT nombre, ST_Distance(geom::GEOGRAPHY, ST_MakePoint(-99.13, 19.43)::GEOGRAPHY) AS dist_m
FROM geo.puntos_interes
ORDER BY dist_m
LIMIT 10;
```

---

## Detener los servicios

```bash
docker compose down          # detiene contenedores (preserva datos)
docker compose down -v       # detiene y elimina volúmenes (borra datos)
```
