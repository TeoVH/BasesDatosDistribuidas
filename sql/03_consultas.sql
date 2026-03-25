-- ============================================================
-- SI3009 - Bases de Datos Avanzadas
-- Script 03: Consultas, Análisis y Evidencias
-- ============================================================
-- Ejecutar en pg-primary y en réplicas para comparar resultados
-- ============================================================

-- ============================================================
-- SECCIÓN A: DEMOSTRACIÓN DE PARTITION PRUNING
-- (Evidencia de particionamiento efectivo)
-- ============================================================

-- A1. Consulta SIN filtro de fecha → escanea TODAS las particiones (scatter-gather)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id_sensor, AVG(valor) AS promedio
FROM medicion
WHERE id_sensor = 1
GROUP BY id_sensor;

-- A2. Consulta CON filtro de fecha → partition pruning (solo 1 partición)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id_sensor, AVG(valor) AS promedio
FROM medicion
WHERE id_sensor = 1
  AND fecha_hora BETWEEN '2024-01-01' AND '2024-01-31 23:59:59'
GROUP BY id_sensor;

-- A3. Consulta en rango multi-partición (3 meses) → pruning parcial
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    DATE_TRUNC('month', fecha_hora) AS mes,
    id_sensor,
    AVG(valor)    AS promedio,
    MAX(valor)    AS maximo,
    MIN(valor)    AS minimo,
    COUNT(*)      AS total_lecturas
FROM medicion
WHERE fecha_hora BETWEEN '2024-01-01' AND '2024-03-31 23:59:59'
  AND id_sensor IN (1, 2, 5)
GROUP BY mes, id_sensor
ORDER BY mes, id_sensor;

-- ============================================================
-- SECCIÓN B: CONSULTAS ANALÍTICAS PRINCIPALES
-- ============================================================

-- B1. Promedio diario de PM2.5 por estación (último trimestre disponible)
SELECT
    e.codigo                          AS estacion,
    e.nombre                          AS nombre_estacion,
    r.nombre                          AS region,
    DATE_TRUNC('day', m.fecha_hora)   AS dia,
    ROUND(AVG(m.valor)::NUMERIC, 2)   AS pm25_promedio,
    ROUND(MAX(m.valor)::NUMERIC, 2)   AS pm25_maximo,
    COUNT(*)                          AS lecturas
FROM medicion m
JOIN sensor s ON s.id_sensor = m.id_sensor
JOIN tipo_contaminante tc ON tc.id_tipo = s.id_tipo AND tc.codigo = 'PM2_5'
JOIN estacion e ON e.id_estacion = s.id_estacion
JOIN region r   ON r.id_region   = e.id_region
WHERE m.fecha_hora BETWEEN '2025-01-01' AND '2025-03-31 23:59:59'
  AND m.calidad = 1
GROUP BY e.codigo, e.nombre, r.nombre, dia
ORDER BY dia DESC, pm25_promedio DESC;

-- B2. Ranking de estaciones por nivel de contaminación PM2.5 (2024)
SELECT
    e.codigo,
    e.nombre,
    r.nombre                              AS region,
    ROUND(AVG(m.valor)::NUMERIC, 2)       AS pm25_anual_promedio,
    COUNT(*) FILTER (WHERE m.valor >= 25) AS horas_sobre_umbral,
    COUNT(*) FILTER (WHERE m.valor >= 75) AS horas_nivel_critico,
    COUNT(*)                              AS total_lecturas,
    RANK() OVER (ORDER BY AVG(m.valor) DESC) AS ranking_contaminacion
FROM medicion m
JOIN sensor s  ON s.id_sensor    = m.id_sensor
JOIN tipo_contaminante tc ON tc.id_tipo = s.id_tipo AND tc.codigo = 'PM2_5'
JOIN estacion e ON e.id_estacion = s.id_estacion
JOIN region r   ON r.id_region   = e.id_region
WHERE m.fecha_hora BETWEEN '2024-01-01' AND '2024-12-31 23:59:59'
  AND m.calidad IN (1, 2)
GROUP BY e.codigo, e.nombre, r.nombre
ORDER BY pm25_anual_promedio DESC;

-- B3. Detección de horas pico (patrón horario de contaminación)
SELECT
    EXTRACT(HOUR FROM m.fecha_hora)       AS hora_del_dia,
    ROUND(AVG(m.valor)::NUMERIC, 2)       AS pm25_promedio,
    ROUND(STDDEV(m.valor)::NUMERIC, 2)    AS desviacion_estandar,
    COUNT(*)                              AS total_lecturas
FROM medicion m
JOIN sensor s ON s.id_sensor = m.id_sensor
JOIN tipo_contaminante tc ON tc.id_tipo = s.id_tipo AND tc.codigo = 'PM2_5'
WHERE m.fecha_hora BETWEEN '2024-01-01' AND '2024-12-31 23:59:59'
  AND m.calidad = 1
GROUP BY hora_del_dia
ORDER BY hora_del_dia;

-- B4. Alertas por estación y mes
SELECT
    e.codigo,
    e.nombre,
    TO_CHAR(a.fecha_hora, 'YYYY-MM')  AS mes,
    COUNT(*) FILTER (WHERE a.nivel = 'ADVERTENCIA') AS advertencias,
    COUNT(*) FILTER (WHERE a.nivel = 'CRITICO')     AS criticas,
    COUNT(*)                                         AS total_alertas,
    COUNT(*) FILTER (WHERE a.atendida = TRUE)        AS atendidas,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE a.atendida = TRUE) / COUNT(*), 1
    )                                               AS pct_atendidas
FROM alerta a
JOIN sensor s  ON s.id_sensor    = a.id_sensor
JOIN estacion e ON e.id_estacion = s.id_estacion
GROUP BY e.codigo, e.nombre, mes
ORDER BY mes DESC, total_alertas DESC;

-- B5. Estado de calibración de sensores (cuáles necesitan atención)
SELECT
    s.id_sensor,
    s.numero_serie,
    e.codigo           AS estacion,
    tc.codigo          AS tipo_sensor,
    c.fecha_calibracion AS ultima_calibracion,
    c.resultado        AS ultimo_resultado,
    NOW()::DATE - c.fecha_calibracion::DATE AS dias_desde_calibracion,
    CASE
        WHEN c.resultado = 'RECHAZADO'                           THEN '🔴 REQUIERE REEMPLAZO'
        WHEN NOW()::DATE - c.fecha_calibracion::DATE > 180      THEN '🟡 CALIBRACIÓN VENCIDA'
        WHEN NOW()::DATE - c.fecha_calibracion::DATE > 90       THEN '🟠 PRÓXIMA CALIBRACIÓN'
        ELSE                                                          '🟢 OK'
    END AS estado
FROM sensor s
JOIN estacion e ON e.id_estacion = s.id_estacion
JOIN tipo_contaminante tc ON tc.id_tipo = s.id_tipo
LEFT JOIN LATERAL (
    SELECT fecha_calibracion, resultado
    FROM calibracion
    WHERE id_sensor = s.id_sensor
    ORDER BY fecha_calibracion DESC
    LIMIT 1
) c ON TRUE
WHERE s.activo = TRUE
ORDER BY dias_desde_calibracion DESC NULLS FIRST;

-- ============================================================
-- SECCIÓN C: ANÁLISIS DE COSTO DE JOIN DISTRIBUIDO
-- (Evidencia para el análisis de particionamiento)
-- ============================================================

-- C1. JOIN entre medicion (particionada) y tablas maestras
-- Este es el "costo del JOIN distribuido" a analizar
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    e.nombre,
    tc.codigo,
    DATE_TRUNC('month', m.fecha_hora) AS mes,
    AVG(m.valor)
FROM medicion m
JOIN sensor s ON s.id_sensor = m.id_sensor
JOIN estacion e ON e.id_estacion = s.id_estacion
JOIN tipo_contaminante tc ON tc.id_tipo = s.id_tipo
WHERE m.fecha_hora BETWEEN '2024-01-01' AND '2024-03-31'
GROUP BY e.nombre, tc.codigo, mes;

-- ============================================================
-- SECCIÓN D: REPLICACIÓN - CONSISTENCIA
-- Verificar lag de replicación (ejecutar en pg-primary)
-- ============================================================

-- D1. Estado de las réplicas conectadas
SELECT
    client_addr,
    application_name,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    write_lag,
    flush_lag,
    replay_lag,
    sync_state
FROM pg_stat_replication
ORDER BY application_name;

-- D2. Verificar si somos primario o réplica
SELECT
    CASE
        WHEN pg_is_in_recovery() THEN 'RÉPLICA (standby)'
        ELSE 'PRIMARIO'
    END AS rol_nodo,
    pg_current_wal_lsn()   AS lsn_actual,
    NOW()                  AS timestamp_consulta;

-- D3. En réplicas: medir lag vs primario
-- (Ejecutar en pg-replica1 y pg-replica2)
SELECT
    now() - pg_last_xact_replay_timestamp() AS replication_lag,
    pg_is_in_recovery()                     AS es_replica,
    pg_last_wal_receive_lsn()               AS ultimo_wal_recibido,
    pg_last_wal_replay_lsn()                AS ultimo_wal_aplicado;

-- ============================================================
-- SECCIÓN E: PRUEBA DE CONSISTENCIA W + R > N
-- RF=3 (1 primary + 2 replicas), W=2, R=1 → W+R=3 > N=3 → NO garantiza fuerte
-- RF=3, W=2, R=2 → W+R=4 > N=3 → SÍ garantiza consistencia fuerte
-- ============================================================

-- E1. Escritura de prueba (en pg-primary, modo SYNCHRONOUS_COMMIT=on)
-- Confirma que la escritura llegó al menos a 1 réplica síncrona
SET synchronous_commit = on;

INSERT INTO medicion (id_sensor, fecha_hora, valor, calidad)
VALUES (1, NOW(), 22.5, 1)
RETURNING id_medicion, fecha_hora, 'Escritura síncrona confirmada' AS nota;

-- E2. Escritura asíncrona (menor latencia, sin garantía inmediata)
SET synchronous_commit = off;

INSERT INTO medicion (id_sensor, fecha_hora, valor, calidad)
VALUES (1, NOW() + INTERVAL '1 second', 23.1, 1)
RETURNING id_medicion, fecha_hora, 'Escritura asíncrona (puede no estar en réplica aún)' AS nota;

-- Restaurar modo por defecto
SET synchronous_commit = on;

-- E3. Lectura inmediata después de escritura (ejecutar en réplica)
-- Puede mostrar lag si la réplica es asíncrona
SELECT id_medicion, fecha_hora, valor
FROM medicion
WHERE id_sensor = 1
  AND fecha_hora >= NOW() - INTERVAL '5 seconds'
ORDER BY fecha_hora DESC
LIMIT 5;
