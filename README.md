# SI3009 - Red de Monitoreo Ambiental Distribuida
## Guía de despliegue en EC2 Amazon Linux 2023

---

## Estructura del proyecto

```
monitoreo-ambiental/
├── docker-compose.yml
├── docker/
│   ├── Dockerfile
│   ├── config/
│   │   ├── postgresql.conf     ← Configuración de PostgreSQL (primario)
│   │   └── pg_hba.conf         ← Control de acceso
│   ├── init/
│   │   ├── 01_init_primary.sh  ← Crea usuario replicator y slots
│   │   └── 02_init_schema.sql  ← DDL completo (se replica automáticamente)
│   ├── replica-setup/
│   │   └── setup_replica.sh    ← Script de pg_basebackup
│   └── pgadmin-servers.json
└── sql/
    ├── 01_ddl.sql              ← DDL con comentarios académicos
    ├── 02_poblacion.sql        ← Datos de prueba
    └── 03_consultas.sql        ← Consultas, EXPLAIN ANALYZE, evidencias
```

---

## 1. Preparar la instancia EC2

### Instalar Docker en Amazon Linux 2023

```bash
# Actualizar paquetes
sudo dnf update -y

# Instalar Docker
sudo dnf install -y docker

# Iniciar y habilitar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Agregar usuario al grupo docker (evita usar sudo en cada comando)
sudo usermod -aG docker $USER

# IMPORTANTE: cerrar sesión y volver a conectarse para que el grupo surta efecto
exit
# reconectarse por SSH
```

### Instalar Docker Compose

```bash
# Docker Compose como plugin (recomendado en AL2023)
sudo dnf install -y docker-compose-plugin

# Verificar instalación
docker compose version
# Debe mostrar: Docker Compose version v2.x.x
```

---

## 2. Subir el proyecto a EC2

```bash
# Opción A: desde tu máquina local con scp
scp -i tu-key.pem -r monitoreo-ambiental/ ec2-user@<IP-EC2>:~/

# Opción B: clonar desde un repositorio git
# git clone <tu-repo> monitoreo-ambiental

# Entrar al directorio
cd monitoreo-ambiental

# Dar permisos de ejecución a los scripts
chmod +x docker/init/01_init_primary.sh
chmod +x docker/replica-setup/setup_replica.sh
```

---

## 3. Levantar el cluster

```bash
# Paso 1: Levantar solo el primario y esperar que esté healthy
docker compose up -d pg-primary

# Verificar que el primario esté listo (esperar "healthy")
watch docker compose ps

# Paso 2: Cuando pg-primary esté healthy, levantar las réplicas
docker compose up -d pg-replica1 pg-replica2

# Paso 3 (opcional): Levantar PgAdmin
docker compose up -d pgadmin

# Ver todos los servicios
docker compose ps
```

---

## 4. Verificar la replicación

```bash
# Conectarse al primario
docker exec -it pg-primary psql -U admin_monitoreo -d monitoreo_ambiental

# Dentro de psql - verificar réplicas conectadas:
SELECT client_addr, application_name, state, sync_state FROM pg_stat_replication;
# Debe mostrar replica1 (sync) y replica2 (async)

# Salir
\q
```

---

## 5. Cargar los datos

```bash
# Ejecutar el script de población en el primario
docker exec -i pg-primary psql \
    -U admin_monitoreo \
    -d monitoreo_ambiental \
    < sql/02_poblacion.sql

# Verificar que las réplicas tienen los datos
docker exec -it pg-replica1 psql -U admin_monitoreo -d monitoreo_ambiental \
    -c "SELECT COUNT(*) FROM medicion;"
```

---

## 6. Ejecutar consultas y obtener evidencias

```bash
# En el primario
docker exec -it pg-primary psql -U admin_monitoreo -d monitoreo_ambiental \
    -f /scripts/sql/03_consultas.sql

# En réplica 1 (síncrona) - para comparar
docker exec -it pg-replica1 psql -U admin_monitoreo -d monitoreo_ambiental \
    -c "SELECT pg_is_in_recovery(), now() - pg_last_xact_replay_timestamp() AS lag;"

# En réplica 2 (asíncrona)
docker exec -it pg-replica2 psql -U admin_monitoreo -d monitoreo_ambiental \
    -c "SELECT pg_is_in_recovery(), now() - pg_last_xact_replay_timestamp() AS lag;"
```

---

## 7. Comandos útiles de operación

```bash
# Ver logs de un nodo
docker compose logs -f pg-primary
docker compose logs -f pg-replica1

# Ver tamaño de volúmenes
docker system df -v

# Detener todo
docker compose down

# Detener y eliminar volúmenes (⚠️ borra los datos)
docker compose down -v

# Reiniciar solo un nodo
docker compose restart pg-replica2

# Conectarse a cada nodo
docker exec -it pg-primary   psql -U admin_monitoreo -d monitoreo_ambiental
docker exec -it pg-replica1  psql -U admin_monitoreo -d monitoreo_ambiental
docker exec -it pg-replica2  psql -U admin_monitoreo -d monitoreo_ambiental
```

---

## 8. Puertos y acceso

| Servicio    | Puerto EC2 | Descripción                     |
|-------------|------------|---------------------------------|
| pg-primary  | 5432       | PostgreSQL primario (R/W)       |
| pg-replica1 | 5433       | Réplica síncrona (solo lectura) |
| pg-replica2 | 5434       | Réplica asíncrona (solo lectura)|
| pgadmin     | 8080       | Interfaz web de administración  |

> **Security Group EC2**: abrir los puertos 5432, 5433, 5434 y 8080 desde tu IP si quieres conectarte externamente (por ejemplo desde DBeaver o pgAdmin local).

---

## 9. Credenciales

| Usuario          | Contraseña          | Rol                    |
|------------------|---------------------|------------------------|
| admin_monitoreo  | admin_pass_2024     | Superusuario de la BD  |
| replicator       | replicator_pass_2024| Solo replicación       |
| readonly_user    | readonly_pass_2024  | Solo lectura           |
| admin@monitoreo.local | admin_2024    | PgAdmin (web)          |

---

## Topología de replicación

```
                    ┌─────────────────────────┐
                    │       pg-primary        │
                    │  172.28.1.10 : 5432     │
                    │  (lectura + escritura)  │
                    └──────────┬──────────────┘
                               │ WAL Streaming
               ┌───────────────┼───────────────┐
               │ SÍNCRONA      │               │ ASÍNCRONA
               ▼               │               ▼
   ┌──────────────────┐        │   ┌──────────────────┐
   │   pg-replica1    │        │   │   pg-replica2    │
   │ 172.28.1.11:5433 │        │   │ 172.28.1.12:5434 │
   │  (solo lectura)  │        │   │  (solo lectura)  │
   └──────────────────┘        │   └──────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │      pgadmin        │
                    │  172.28.1.20 : 8080 │
                    └─────────────────────┘
```
