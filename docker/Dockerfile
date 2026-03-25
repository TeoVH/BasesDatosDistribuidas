# ============================================================
# SI3009 - Bases de Datos Avanzadas
# Dockerfile: Nodo PostgreSQL 15 con soporte de replicación
# ============================================================

FROM postgres:15-alpine

LABEL maintainer="SI3009-MonitoreoAmbiental"
LABEL description="Nodo PostgreSQL para red de monitoreo ambiental distribuida"

# Copiar scripts de inicialización
# Docker ejecuta automáticamente los archivos .sql y .sh
# en /docker-entrypoint-initdb.d/ en orden alfabético,
# SOLO cuando el volumen de datos está vacío (primer arranque)
COPY init/ /docker-entrypoint-initdb.d/

# Copiar configuraciones personalizadas de PostgreSQL
COPY config/postgresql.conf /etc/postgresql/postgresql.conf
COPY config/pg_hba.conf     /etc/postgresql/pg_hba.conf

# Puerto estándar de PostgreSQL
EXPOSE 5432

# Comando con archivo de configuración explícito
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
