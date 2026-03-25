-- ============================================================
-- SI3009 - Bases de Datos Avanzadas
-- Examen Parcial 2: Bases de Datos Distribuidas
-- Contexto: Red de Monitoreo Ambiental
-- ============================================================
-- Script 01: DDL - Creación de tablas y particionamiento
-- Nodo: PRIMARY (ejecutar primero en pg-primary)
-- ============================================================

-- Extensiones útiles
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- ============================================================
-- TABLAS MAESTRAS
-- ============================================================

-- Regiones geográficas donde operan las estaciones
CREATE TABLE region (
    id_region     SERIAL PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL,
    departamento  VARCHAR(100) NOT NULL,
    pais          VARCHAR(50)  NOT NULL DEFAULT 'Colombia',
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Estaciones de monitoreo ambiental (fijas en el territorio)
CREATE TABLE estacion (
    id_estacion   SERIAL PRIMARY KEY,
    id_region     INT          NOT NULL REFERENCES region(id_region),
    codigo        VARCHAR(20)  NOT NULL UNIQUE,
    nombre        VARCHAR(150) NOT NULL,
    latitud       NUMERIC(9,6) NOT NULL,
    longitud      NUMERIC(9,6) NOT NULL,
    altitud_msnm  INT,
    activa        BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_instalacion DATE     NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Catálogo de tipos de contaminante / variable ambiental
CREATE TABLE tipo_contaminante (
    id_tipo       SERIAL PRIMARY KEY,
    codigo        VARCHAR(20)  NOT NULL UNIQUE,  -- PM2.5, PM10, CO2, NO2, O3, TEMP, HUM
    nombre        VARCHAR(100) NOT NULL,
    unidad        VARCHAR(20)  NOT NULL,          -- µg/m³, ppm, °C, %
    umbral_alerta NUMERIC(10,4),                  -- valor a partir del cual se genera alerta
    umbral_critico NUMERIC(10,4),
    descripcion   TEXT
);

-- Sensores instalados en cada estación
CREATE TABLE sensor (
    id_sensor     SERIAL PRIMARY KEY,
    id_estacion   INT          NOT NULL REFERENCES estacion(id_estacion),
    id_tipo       INT          NOT NULL REFERENCES tipo_contaminante(id_tipo),
    modelo        VARCHAR(100),
    numero_serie  VARCHAR(100) UNIQUE,
    fecha_instalacion DATE     NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLAS DE TRANSACCIONES (con particionamiento)
-- ============================================================

-- Tabla principal de mediciones - PARTICIONADA POR RANGO (fecha)
-- Estrategia: RANGE sobre fecha_hora → partición mensual
-- Justificación: Las consultas típicas filtran por rango de fechas
--   (últimas 24h, último mes, último año). El particionamiento range
--   permite partition pruning automático, reduciendo I/O al evitar
--   escanear particiones fuera del rango consultado.
CREATE TABLE medicion (
    id_medicion   BIGSERIAL,
    id_sensor     INT          NOT NULL,
    fecha_hora    TIMESTAMP    NOT NULL,          -- CLAVE DE PARTICIÓN
    valor         NUMERIC(10,4) NOT NULL,
    calidad       SMALLINT     NOT NULL DEFAULT 1, -- 1=buena, 2=dudosa, 3=mala
    PRIMARY KEY (id_medicion, fecha_hora)          -- PK debe incluir la clave de partición
) PARTITION BY RANGE (fecha_hora);

-- Particiones mensuales de medicion (2024-2025)
CREATE TABLE medicion_2024_01 PARTITION OF medicion
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE medicion_2024_02 PARTITION OF medicion
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE medicion_2024_03 PARTITION OF medicion
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

CREATE TABLE medicion_2024_04 PARTITION OF medicion
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

CREATE TABLE medicion_2024_05 PARTITION OF medicion
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');

CREATE TABLE medicion_2024_06 PARTITION OF medicion
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

CREATE TABLE medicion_2024_07 PARTITION OF medicion
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');

CREATE TABLE medicion_2024_08 PARTITION OF medicion
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');

CREATE TABLE medicion_2024_09 PARTITION OF medicion
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');

CREATE TABLE medicion_2024_10 PARTITION OF medicion
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

CREATE TABLE medicion_2024_11 PARTITION OF medicion
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');

CREATE TABLE medicion_2024_12 PARTITION OF medicion
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

CREATE TABLE medicion_2025_01 PARTITION OF medicion
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE medicion_2025_02 PARTITION OF medicion
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE medicion_2025_03 PARTITION OF medicion
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE TABLE medicion_2025_04 PARTITION OF medicion
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

-- Alertas generadas cuando una medición supera el umbral
CREATE TABLE alerta (
    id_alerta     BIGSERIAL    PRIMARY KEY,
    id_medicion   BIGINT       NOT NULL,
    id_sensor     INT          NOT NULL REFERENCES sensor(id_sensor),
    fecha_hora    TIMESTAMP    NOT NULL,
    nivel         VARCHAR(20)  NOT NULL CHECK (nivel IN ('ADVERTENCIA','CRITICO')),
    valor_medido  NUMERIC(10,4) NOT NULL,
    umbral        NUMERIC(10,4) NOT NULL,
    atendida      BOOLEAN      NOT NULL DEFAULT FALSE,
    fecha_atencion TIMESTAMP
);

-- Registro de calibraciones de sensores
CREATE TABLE calibracion (
    id_calibracion SERIAL      PRIMARY KEY,
    id_sensor      INT         NOT NULL REFERENCES sensor(id_sensor),
    fecha_calibracion TIMESTAMP NOT NULL,
    tecnico        VARCHAR(100) NOT NULL,
    resultado      VARCHAR(20)  NOT NULL CHECK (resultado IN ('APROBADO','RECHAZADO','AJUSTADO')),
    valor_antes    NUMERIC(10,4),
    valor_despues  NUMERIC(10,4),
    observaciones  TEXT,
    created_at     TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- ÍNDICES
-- ============================================================

-- Índices en tabla maestra estacion
CREATE INDEX idx_estacion_region   ON estacion(id_region);
CREATE INDEX idx_estacion_activa   ON estacion(activa);

-- Índices en sensor
CREATE INDEX idx_sensor_estacion   ON sensor(id_estacion);
CREATE INDEX idx_sensor_tipo       ON sensor(id_tipo);

-- Índices en medicion (se propagan a cada partición)
CREATE INDEX idx_medicion_sensor   ON medicion(id_sensor, fecha_hora);
CREATE INDEX idx_medicion_calidad  ON medicion(calidad);

-- Índices en alerta
CREATE INDEX idx_alerta_sensor     ON alerta(id_sensor);
CREATE INDEX idx_alerta_fecha      ON alerta(fecha_hora);
CREATE INDEX idx_alerta_atendida   ON alerta(atendida) WHERE atendida = FALSE;

-- Índices en calibracion
CREATE INDEX idx_calibracion_sensor ON calibracion(id_sensor);

-- ============================================================
-- FOREIGN KEYS en medicion (referencia a sensor)
-- No se puede hacer directamente en tabla particionada en PG < 16
-- Se aplica a nivel de partición o se maneja por aplicación
-- ============================================================

-- Verificar estructura
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS tamanio
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
