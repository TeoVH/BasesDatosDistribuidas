#!/bin/bash
# ============================================================
# replica-setup/setup_replica.sh
# Configura un nodo réplica usando pg_basebackup
#
# USO: ejecutar DENTRO del contenedor de la réplica después
# de que el primario esté corriendo
#
# docker exec -it pg-replica1 bash /replica-setup/setup_replica.sh
# ============================================================

set -e

PRIMARY_HOST="${PRIMARY_HOST:-pg-primary}"
PRIMARY_PORT="${PRIMARY_PORT:-5432}"
REPLICA_SLOT="${REPLICA_SLOT:-replica1_slot}"
PGDATA="${PGDATA:-/var/lib/postgresql/data}"
REPLICATION_USER="replicator"
REPLICATION_PASS="replicator_pass_2024"

echo ">>> [REPLICA SETUP] Iniciando configuración de réplica..."
echo "    Primario: $PRIMARY_HOST:$PRIMARY_PORT"
echo "    Slot: $REPLICA_SLOT"
echo "    PGDATA: $PGDATA"

# Detener PostgreSQL si está corriendo
pg_ctl -D "$PGDATA" stop -m fast 2>/dev/null || true

# Limpiar directorio de datos
echo ">>> Limpiando directorio de datos..."
rm -rf "${PGDATA:?}"/*

# Realizar base backup desde el primario
echo ">>> Ejecutando pg_basebackup..."
PGPASSWORD="$REPLICATION_PASS" pg_basebackup \
    -h "$PRIMARY_HOST" \
    -p "$PRIMARY_PORT" \
    -U "$REPLICATION_USER" \
    -D "$PGDATA" \
    -Fp \
    -Xs \
    -P \
    -R \
    --slot="$REPLICA_SLOT"

# El flag -R crea automáticamente standby.signal y postgresql.auto.conf
# con los parámetros de conexión al primario

# Agregar configuración adicional de recuperación
cat >> "$PGDATA/postgresql.auto.conf" <<EOF

# Configuración adicional de réplica
recovery_target_timeline = 'latest'
hot_standby = on
hot_standby_feedback = on
EOF

echo ">>> [REPLICA SETUP] Configuración completada."
echo "    Iniciando PostgreSQL en modo standby..."

# Iniciar PostgreSQL
postgres -D "$PGDATA"
