#!/bin/bash
# ============================================================
# init/01_init_primary.sh
# Inicialización del nodo PRIMARIO
# Se ejecuta automáticamente en el primer arranque del contenedor
# ============================================================

set -e

echo ">>> [INIT] Configurando nodo primario..."

# Crear usuario de replicación (con permisos solo de replicación)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    -- Usuario dedicado para replicación (sin acceso a datos de negocio)
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator_pass_2024';

    -- Usuario de solo lectura para las réplicas y dashboards
    CREATE USER readonly_user WITH ENCRYPTED PASSWORD 'readonly_pass_2024';
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO readonly_user;
    GRANT USAGE ON SCHEMA public TO readonly_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT ON TABLES TO readonly_user;

    -- Slots de replicación (garantiza que el WAL se retiene hasta que la réplica lo lea)
    SELECT pg_create_physical_replication_slot('replica1_slot');
    SELECT pg_create_physical_replication_slot('replica2_slot');

EOSQL

echo ">>> [INIT] Usuarios y slots de replicación creados."
