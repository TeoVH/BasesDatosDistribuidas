-- ============================================================
-- SI3009 - Bases de Datos Avanzadas
-- Script 02: Población de datos
-- Ejecutar DESPUÉS de 01_ddl.sql en pg-primary
-- ============================================================

-- ============================================================
-- TABLAS MAESTRAS
-- ============================================================

INSERT INTO region (nombre, departamento, pais) VALUES
    ('Valle de Aburrá',        'Antioquia',       'Colombia'),
    ('Sabana de Bogotá',       'Cundinamarca',    'Colombia'),
    ('Área Metropolitana Cali','Valle del Cauca',  'Colombia'),
    ('Costa Atlántica Norte',  'Atlántico',       'Colombia'),
    ('Altiplano Cundiboyacense','Boyacá',          'Colombia');

INSERT INTO tipo_contaminante (codigo, nombre, unidad, umbral_alerta, umbral_critico, descripcion) VALUES
    ('PM2_5', 'Material Particulado 2.5µm', 'µg/m³',  25.0,   75.0,  'Partículas finas suspendidas en el aire'),
    ('PM10',  'Material Particulado 10µm',  'µg/m³',  50.0,  150.0,  'Partículas gruesas suspendidas en el aire'),
    ('CO2',   'Dióxido de Carbono',         'ppm',   1000.0, 2000.0,  'Concentración de CO2 ambiental'),
    ('NO2',   'Dióxido de Nitrógeno',       'µg/m³',  40.0,  200.0,  'Gas producido por combustión'),
    ('O3',    'Ozono Troposférico',          'µg/m³', 100.0,  180.0,  'Ozono a nivel del suelo'),
    ('TEMP',  'Temperatura Ambiental',       '°C',     38.0,   42.0,  'Temperatura del aire'),
    ('HUM',   'Humedad Relativa',            '%',      90.0,   95.0,  'Porcentaje de humedad en el aire');

INSERT INTO estacion (id_region, codigo, nombre, latitud, longitud, altitud_msnm, activa, fecha_instalacion) VALUES
    (1, 'EST-001', 'Estación Bello Centro',        6.3366, -75.5578, 1450, TRUE, '2022-01-15'),
    (1, 'EST-002', 'Estación Itagüí Industrial',   6.1847, -75.5991, 1610, TRUE, '2022-03-10'),
    (1, 'EST-003', 'Estación Medellín Poblado',    6.2086, -75.5659, 1495, TRUE, '2021-08-20'),
    (1, 'EST-004', 'Estación Envigado Sur',        6.1679, -75.5872, 1570, TRUE, '2023-02-01'),
    (2, 'EST-005', 'Estación Bogotá Fontibón',     4.6718, -74.1469, 2548, TRUE, '2021-11-05'),
    (2, 'EST-006', 'Estación Bogotá Usaquén',      4.7040, -74.0317, 2580, TRUE, '2022-06-15'),
    (3, 'EST-007', 'Estación Cali Aguablanca',     3.4200, -76.5000, 985,  TRUE, '2023-01-20'),
    (4, 'EST-008', 'Estación Barranquilla Puerto', 10.9639,-74.7964, 18,   TRUE, '2022-09-01'),
    (5, 'EST-009', 'Estación Tunja Centro',         5.5353,-73.3678, 2782, TRUE, '2023-05-10'),
    (1, 'EST-010', 'Estación Caldas Autopista',    6.0922, -75.6358, 1750, FALSE,'2021-04-01');

-- Sensores: cada estación activa tiene al menos PM2.5, PM10 y TEMP
INSERT INTO sensor (id_estacion, id_tipo, modelo, numero_serie, fecha_instalacion, activo) VALUES
    -- EST-001 Bello
    (1, 1, 'Grimm 11-D',    'SN-001-PM25', '2022-01-15', TRUE),
    (1, 2, 'Grimm 11-D',    'SN-001-PM10', '2022-01-15', TRUE),
    (1, 6, 'Vaisala HMP110','SN-001-TEMP', '2022-01-15', TRUE),
    (1, 4, 'Teledyne T200', 'SN-001-NO2',  '2022-06-01', TRUE),
    -- EST-002 Itagüí
    (2, 1, 'Grimm 11-D',    'SN-002-PM25', '2022-03-10', TRUE),
    (2, 2, 'Grimm 11-D',    'SN-002-PM10', '2022-03-10', TRUE),
    (2, 6, 'Vaisala HMP110','SN-002-TEMP', '2022-03-10', TRUE),
    (2, 3, 'Vaisala GMP343','SN-002-CO2',  '2022-03-10', TRUE),
    -- EST-003 Medellín Poblado
    (3, 1, 'Grimm 11-D',    'SN-003-PM25', '2021-08-20', TRUE),
    (3, 2, 'TSI DustTrak',  'SN-003-PM10', '2021-08-20', TRUE),
    (3, 6, 'Vaisala HMP110','SN-003-TEMP', '2021-08-20', TRUE),
    (3, 7, 'Vaisala HMP110','SN-003-HUM',  '2021-08-20', TRUE),
    (3, 5, 'Teledyne T400', 'SN-003-O3',   '2022-01-10', TRUE),
    -- EST-004 Envigado
    (4, 1, 'Grimm 11-D',    'SN-004-PM25', '2023-02-01', TRUE),
    (4, 2, 'Grimm 11-D',    'SN-004-PM10', '2023-02-01', TRUE),
    (4, 6, 'Vaisala HMP110','SN-004-TEMP', '2023-02-01', TRUE),
    -- EST-005 Bogotá Fontibón
    (5, 1, 'Grimm 11-D',    'SN-005-PM25', '2021-11-05', TRUE),
    (5, 2, 'Grimm 11-D',    'SN-005-PM10', '2021-11-05', TRUE),
    (5, 6, 'Vaisala HMP110','SN-005-TEMP', '2021-11-05', TRUE),
    (5, 4, 'Teledyne T200', 'SN-005-NO2',  '2022-02-15', TRUE),
    -- EST-006 Bogotá Usaquén
    (6, 1, 'Grimm 11-D',    'SN-006-PM25', '2022-06-15', TRUE),
    (6, 6, 'Vaisala HMP110','SN-006-TEMP', '2022-06-15', TRUE),
    (6, 7, 'Vaisala HMP110','SN-006-HUM',  '2022-06-15', TRUE),
    -- EST-007 Cali
    (7, 1, 'Grimm 11-D',    'SN-007-PM25', '2023-01-20', TRUE),
    (7, 2, 'Grimm 11-D',    'SN-007-PM10', '2023-01-20', TRUE),
    (7, 6, 'Vaisala HMP110','SN-007-TEMP', '2023-01-20', TRUE),
    -- EST-008 Barranquilla
    (8, 1, 'Grimm 11-D',    'SN-008-PM25', '2022-09-01', TRUE),
    (8, 6, 'Vaisala HMP110','SN-008-TEMP', '2022-09-01', TRUE),
    (8, 7, 'Vaisala HMP110','SN-008-HUM',  '2022-09-01', TRUE),
    -- EST-009 Tunja
    (9, 1, 'Grimm 11-D',    'SN-009-PM25', '2023-05-10', TRUE),
    (9, 6, 'Vaisala HMP110','SN-009-TEMP', '2023-05-10', TRUE);

-- ============================================================
-- CALIBRACIONES
-- ============================================================

INSERT INTO calibracion (id_sensor, fecha_calibracion, tecnico, resultado, valor_antes, valor_despues, observaciones) VALUES
    (1,  '2024-01-10 09:00', 'Carlos Ríos',    'APROBADO',  12.3, 12.1, 'Calibración rutinaria'),
    (2,  '2024-01-10 10:30', 'Carlos Ríos',    'AJUSTADO',  48.5, 47.8, 'Ajuste menor de cero'),
    (5,  '2024-02-05 08:00', 'Laura Gómez',    'APROBADO',  22.1, 22.0, NULL),
    (9,  '2024-03-15 14:00', 'Pedro Salcedo',  'RECHAZADO', 18.7, 18.7, 'Sensor dañado, programar reemplazo'),
    (13, '2024-01-20 09:00', 'Carlos Ríos',    'APROBADO',  15.0, 14.9, 'Calibración semestral'),
    (17, '2024-02-28 11:00', 'Laura Gómez',    'AJUSTADO',  28.3, 27.5, 'Deriva detectada, corregida'),
    (21, '2024-03-01 09:00', 'Pedro Salcedo',  'APROBADO',  19.8, 19.7, NULL),
    (1,  '2024-07-10 09:00', 'Carlos Ríos',    'APROBADO',  11.9, 12.0, 'Calibración semestral'),
    (5,  '2024-08-05 08:00', 'Laura Gómez',    'APROBADO',  21.8, 22.1, NULL),
    (17, '2024-09-12 10:00', 'Andrea Torres',  'AJUSTADO',  29.1, 27.8, 'Ajuste por temperatura ambiente');

-- ============================================================
-- MEDICIONES (datos sintéticos realistas)
-- Se generan mediciones horarias para sensores clave
-- en distintos meses para demostrar particionamiento
-- ============================================================

-- Función auxiliar para generar mediciones en un rango
-- (se elimina al final del script)
CREATE OR REPLACE FUNCTION generar_mediciones(
    p_sensor_id INT,
    p_fecha_inicio TIMESTAMP,
    p_fecha_fin    TIMESTAMP,
    p_valor_base   NUMERIC,
    p_variacion    NUMERIC
) RETURNS VOID AS $$
DECLARE
    v_fecha TIMESTAMP := p_fecha_inicio;
    v_valor NUMERIC;
    v_calidad SMALLINT;
BEGIN
    WHILE v_fecha < p_fecha_fin LOOP
        v_valor := p_valor_base
                   + (random() * p_variacion * 2 - p_variacion)
                   + sin(EXTRACT(HOUR FROM v_fecha) * 3.14159 / 12) * (p_variacion * 0.5);
        v_valor := GREATEST(0, ROUND(v_valor::NUMERIC, 4));
        v_calidad := CASE WHEN random() < 0.92 THEN 1
                          WHEN random() < 0.97 THEN 2
                          ELSE 3 END;
        INSERT INTO medicion (id_sensor, fecha_hora, valor, calidad)
        VALUES (p_sensor_id, v_fecha, v_valor, v_calidad);
        v_fecha := v_fecha + INTERVAL '1 hour';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Sensor 1: PM2.5 EST-001 Bello (valor base ~18 µg/m³)
SELECT generar_mediciones(1, '2024-01-01', '2024-04-01', 18.0, 8.0);
SELECT generar_mediciones(1, '2024-07-01', '2024-10-01', 20.0, 9.0);
SELECT generar_mediciones(1, '2025-01-01', '2025-04-01', 17.0, 7.0);

-- Sensor 2: PM10 EST-001 Bello (valor base ~40 µg/m³)
SELECT generar_mediciones(2, '2024-01-01', '2024-04-01', 40.0, 15.0);
SELECT generar_mediciones(2, '2024-07-01', '2024-10-01', 45.0, 18.0);

-- Sensor 5: PM2.5 EST-002 Itagüí (zona industrial, mayor base ~28)
SELECT generar_mediciones(5, '2024-01-01', '2024-04-01', 28.0, 12.0);
SELECT generar_mediciones(5, '2024-07-01', '2024-10-01', 32.0, 14.0);
SELECT generar_mediciones(5, '2025-01-01', '2025-04-01', 26.0, 10.0);

-- Sensor 6: PM10 EST-002 Itagüí
SELECT generar_mediciones(6, '2024-01-01', '2024-04-01', 65.0, 20.0);
SELECT generar_mediciones(6, '2024-07-01', '2024-10-01', 70.0, 22.0);

-- Sensor 9: PM2.5 EST-003 Poblado (zona residencial, valor más bajo ~12)
SELECT generar_mediciones(9, '2024-01-01', '2024-04-01', 12.0, 5.0);
SELECT generar_mediciones(9, '2024-07-01', '2024-10-01', 14.0, 6.0);
SELECT generar_mediciones(9, '2025-01-01', '2025-04-01', 11.0, 5.0);

-- Sensor 17: PM2.5 EST-005 Bogotá Fontibón (altitud alta, base ~22)
SELECT generar_mediciones(17, '2024-01-01', '2024-04-01', 22.0, 9.0);
SELECT generar_mediciones(17, '2024-07-01', '2024-10-01', 24.0, 10.0);

-- Sensor 21: PM2.5 EST-006 Bogotá Usaquén
SELECT generar_mediciones(21, '2024-01-01', '2024-04-01', 15.0, 6.0);
SELECT generar_mediciones(21, '2025-01-01', '2025-04-01', 13.0, 5.0);

-- ============================================================
-- ALERTAS (generadas a partir de mediciones que superan umbral)
-- ============================================================

INSERT INTO alerta (id_medicion, id_sensor, fecha_hora, nivel, valor_medido, umbral, atendida, fecha_atencion)
SELECT
    m.id_medicion,
    m.id_sensor,
    m.fecha_hora,
    CASE WHEN m.valor >= tc.umbral_critico THEN 'CRITICO' ELSE 'ADVERTENCIA' END,
    m.valor,
    CASE WHEN m.valor >= tc.umbral_critico THEN tc.umbral_critico ELSE tc.umbral_alerta END,
    CASE WHEN m.fecha_hora < NOW() - INTERVAL '30 days' THEN TRUE ELSE FALSE END,
    CASE WHEN m.fecha_hora < NOW() - INTERVAL '30 days'
         THEN m.fecha_hora + INTERVAL '2 hours' ELSE NULL END
FROM medicion m
JOIN sensor s ON s.id_sensor = m.id_sensor
JOIN tipo_contaminante tc ON tc.id_tipo = s.id_tipo
WHERE m.valor >= tc.umbral_alerta
  AND tc.umbral_alerta IS NOT NULL
LIMIT 500;  -- limitamos para no sobrecargar

-- Limpiar función auxiliar
DROP FUNCTION generar_mediciones;

-- ============================================================
-- Verificación de carga
-- ============================================================

SELECT 'region'            AS tabla, COUNT(*) AS filas FROM region
UNION ALL
SELECT 'tipo_contaminante',            COUNT(*) FROM tipo_contaminante
UNION ALL
SELECT 'estacion',                     COUNT(*) FROM estacion
UNION ALL
SELECT 'sensor',                       COUNT(*) FROM sensor
UNION ALL
SELECT 'medicion (total)',              COUNT(*) FROM medicion
UNION ALL
SELECT 'alerta',                       COUNT(*) FROM alerta
UNION ALL
SELECT 'calibracion',                  COUNT(*) FROM calibracion
ORDER BY tabla;

-- Verificar distribución por partición
SELECT
    child.relname          AS particion,
    pg_size_pretty(pg_relation_size(child.oid)) AS tamanio,
    psql.n_live_tup        AS filas_estimadas
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child  ON pg_inherits.inhrelid  = child.oid
JOIN pg_stat_user_tables psql ON psql.relname = child.relname
WHERE parent.relname = 'medicion'
ORDER BY child.relname;
