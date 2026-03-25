-- ============================================================
-- init/02_init_schema.sql
-- Crea el esquema completo en el primario.
-- Las réplicas lo recibirán automáticamente vía WAL streaming.
-- ============================================================

-- Este archivo es una copia del DDL para inicialización automática
-- (mismo contenido que sql/01_ddl.sql, sin el SELECT final de verificación)

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

CREATE TABLE region (
    id_region     SERIAL PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL,
    departamento  VARCHAR(100) NOT NULL,
    pais          VARCHAR(50)  NOT NULL DEFAULT 'Colombia',
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

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

CREATE TABLE tipo_contaminante (
    id_tipo        SERIAL PRIMARY KEY,
    codigo         VARCHAR(20)  NOT NULL UNIQUE,
    nombre         VARCHAR(100) NOT NULL,
    unidad         VARCHAR(20)  NOT NULL,
    umbral_alerta  NUMERIC(10,4),
    umbral_critico NUMERIC(10,4),
    descripcion    TEXT
);

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

CREATE TABLE medicion (
    id_medicion   BIGSERIAL,
    id_sensor     INT          NOT NULL,
    fecha_hora    TIMESTAMP    NOT NULL,
    valor         NUMERIC(10,4) NOT NULL,
    calidad       SMALLINT     NOT NULL DEFAULT 1,
    PRIMARY KEY (id_medicion, fecha_hora)
) PARTITION BY RANGE (fecha_hora);

CREATE TABLE medicion_2024_01 PARTITION OF medicion FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE medicion_2024_02 PARTITION OF medicion FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE medicion_2024_03 PARTITION OF medicion FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE medicion_2024_04 PARTITION OF medicion FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE medicion_2024_05 PARTITION OF medicion FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE medicion_2024_06 PARTITION OF medicion FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE medicion_2024_07 PARTITION OF medicion FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE medicion_2024_08 PARTITION OF medicion FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE medicion_2024_09 PARTITION OF medicion FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE medicion_2024_10 PARTITION OF medicion FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE medicion_2024_11 PARTITION OF medicion FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE medicion_2024_12 PARTITION OF medicion FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
CREATE TABLE medicion_2025_01 PARTITION OF medicion FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE medicion_2025_02 PARTITION OF medicion FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE medicion_2025_03 PARTITION OF medicion FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE medicion_2025_04 PARTITION OF medicion FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

CREATE TABLE alerta (
    id_alerta      BIGSERIAL    PRIMARY KEY,
    id_medicion    BIGINT       NOT NULL,
    id_sensor      INT          NOT NULL REFERENCES sensor(id_sensor),
    fecha_hora     TIMESTAMP    NOT NULL,
    nivel          VARCHAR(20)  NOT NULL CHECK (nivel IN ('ADVERTENCIA','CRITICO')),
    valor_medido   NUMERIC(10,4) NOT NULL,
    umbral         NUMERIC(10,4) NOT NULL,
    atendida       BOOLEAN      NOT NULL DEFAULT FALSE,
    fecha_atencion TIMESTAMP
);

CREATE TABLE calibracion (
    id_calibracion    SERIAL      PRIMARY KEY,
    id_sensor         INT         NOT NULL REFERENCES sensor(id_sensor),
    fecha_calibracion TIMESTAMP   NOT NULL,
    tecnico           VARCHAR(100) NOT NULL,
    resultado         VARCHAR(20)  NOT NULL CHECK (resultado IN ('APROBADO','RECHAZADO','AJUSTADO')),
    valor_antes       NUMERIC(10,4),
    valor_despues     NUMERIC(10,4),
    observaciones     TEXT,
    created_at        TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_estacion_region   ON estacion(id_region);
CREATE INDEX idx_estacion_activa   ON estacion(activa);
CREATE INDEX idx_sensor_estacion   ON sensor(id_estacion);
CREATE INDEX idx_sensor_tipo       ON sensor(id_tipo);
CREATE INDEX idx_medicion_sensor   ON medicion(id_sensor, fecha_hora);
CREATE INDEX idx_medicion_calidad  ON medicion(calidad);
CREATE INDEX idx_alerta_sensor     ON alerta(id_sensor);
CREATE INDEX idx_alerta_fecha      ON alerta(fecha_hora);
CREATE INDEX idx_alerta_atendida   ON alerta(atendida) WHERE atendida = FALSE;
CREATE INDEX idx_calibracion_sensor ON calibracion(id_sensor);
