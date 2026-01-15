# Servicios Docker

Este documento detalla cada uno de los 8 servicios Docker que componen el proyecto Equilux.pe.

## Índice de Servicios

1. [Odoo](#1-odoo)
2. [PostgreSQL](#2-postgresql)
3. [Nginx](#3-nginx)
4. [Nginx-Proxy](#4-nginx-proxy)
5. [Let's Encrypt (ACME Companion)](#5-lets-encrypt-acme-companion)
6. [Redis/KeyDB](#6-rediskeydb)
7. [MinIO (S3)](#7-minio-s3)
8. [PgAdmin](#8-pgadmin)

---

## 1. Odoo

### Información General

- **Imagen Base:** `odoo:17.0`
- **Imagen Custom:** Build desde `odoo/Dockerfile`
- **Container Name:** odoo
- **Usuario:** odoo (no-root)

### Puertos

| Puerto | Servicio | Descripción |
|--------|----------|-------------|
| 8069 | HTTP | Puerto principal de la aplicación |
| 8070 | Debug | Puerto para debugpy (VSCode) |
| 8071 | Shell | Puerto para odoo-shell |
| 8072 | WebSocket | Puerto para chat/notificaciones (Gevent) |

### Recursos

**Límites:**
- CPU: 3 cores
- RAM: 6 GB

**Reservas:**
- CPU: 1 core
- RAM: 4 GB

**Configuración de Workers:**
```
WORKERS = CPU * 2 + 1
Ejemplo: 4 CPU → 9 workers
```

### Volúmenes

```yaml
volumes:
  - odoo-data:/var/lib/odoo              # Filestore (persistente)
  - ./odoo/extra-addons:/usr/lib/python3/dist-packages/odoo/extra-addons:ro
  - ./odoo/custom-addons:/usr/lib/python3/dist-packages/odoo/custom-addons:rw
  - ./odoo/odoo.conf:/etc/odoo/odoo.conf:ro
```

### Variables de Entorno Principales

```env
APP_ENV=local                    # Ambiente de ejecución
INIT=                           # Módulos a instalar
UPDATE=                         # Módulos a actualizar
WORKERS=0                       # Número de workers
DEV_MODE=                       # reload,qweb para hot-reload
ADMIN_PASSWD=odoo               # Contraseña master
DB_HOST=postgres
DB_PORT=5432
DB_USER=odoo
DB_PASSWORD=odoo
```

### Dockerfile Personalizado

**Dependencias APT:**
```dockerfile
RUN apt-get update && apt-get install -y \
    zip unzip rsync \
    git git-man less \
    openssh-client libfido2-1 libxmuu1
```

**Dependencias Python (requirements.txt):**
- debugpy (debugging remoto)
- redis (cliente Redis)
- boto3 (AWS S3)
- sentry-sdk (error tracking)
- pandas (procesamiento datos)
- openpyxl (Excel)
- websocket-client
- paramiko (SSH)
- nextcloud-api-wrapper
- html5lib

**Build Process:**
1. Copia `.env` al contenedor
2. Ejecuta `clone-addons.sh` para clonar repos de terceros
3. Genera `odoo.conf` desde variables de entorno con `odoorc.sh`
4. Establece permisos para usuario `odoo`

### Entrypoint

El script `entrypoint.sh` maneja 7 modos de ejecución según `APP_ENV`:

1. **fresh/restore:** Sin BD, ideal para instalación nueva
2. **local:** Desarrollo estándar con hot-reload opcional
3. **debug:** Debugging con debugpy en puerto 8070
4. **testing:** Tests automatizados
5. **full:** Instalación completa de módulos
6. **staging:** Pre-producción con actualización de addons
7. **production:** Optimizado para producción

### Healthcheck

```bash
curl -f http://localhost:8069/web/health || exit 1
```

---

## 2. PostgreSQL

### Información General

- **Imagen Base:** `postgres:16.4`
- **Imagen Custom:** Build desde `postgres/Dockerfile`
- **Container Name:** postgres
- **Usuario:** postgres

### Puerto

- **5432:** Puerto estándar de PostgreSQL

### Recursos

**Límites:**
- CPU: 1 core
- RAM: 2 GB

**Reservas:**
- CPU: 1 core
- RAM: 1 GB

### Volúmenes

```yaml
volumes:
  - pg-data:/var/lib/postgresql/data
  - ./postgres/entrypoint.sh:/docker-entrypoint-initdb.d/entrypoint.sh:ro
```

### Variables de Entorno

```env
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_INITDB_ARGS=--encoding=UTF-8
```

### Extensiones Instaladas

- **UNACCENT:** Búsqueda sin acentos
- **pg_trgm:** Búsqueda por similitud

### Configuración Optimizada

```sql
shared_buffers = 1GB
effective_cache_size = 2GB
maintenance_work_mem = 256MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 64MB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 4
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
max_parallel_maintenance_workers = 2
max_connections = 100
```

### Inicialización (entrypoint.sh)

```bash
# 1. Crear extensión UNACCENT
CREATE EXTENSION IF NOT EXISTS unaccent;

# 2. Crear usuario Odoo con privilegios SUPERUSER
CREATE USER odoo WITH SUPERUSER PASSWORD 'odoo';

# 3. Crear template database
CREATE DATABASE unaccent_template WITH TEMPLATE = template0;
\c unaccent_template
CREATE EXTENSION unaccent;
```

### Comandos Útiles

```bash
# Acceso a psql
./postgres/psql.sh

# Dentro de psql
\l                  # Listar bases de datos
\c database_name    # Conectar a BD
\dt                 # Listar tablas
\du                 # Listar usuarios
```

---

## 3. Nginx

### Información General

- **Imagen:** `fholzer/nginx-brotli:v1.26.2`
- **Container Name:** nginx
- **Características:** Compresión Brotli + Gzip

### Puertos

- **80:** HTTP (interno, no expuesto directamente)

### Recursos

**Límites:**
- CPU: 0.5 core
- RAM: 256 MB

### Volúmenes

```yaml
volumes:
  - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
  - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
```

### Configuración Principal (nginx.conf)

```nginx
worker_processes auto;
worker_connections 1024;

http {
    # Compresión Brotli
    brotli on;
    brotli_comp_level 6;
    brotli_types text/plain text/css application/json application/javascript;

    # Compresión Gzip (fallback)
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript;

    # Logs con métricas
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'upstream: $upstream_response_time';

    client_max_body_size 2G;
    keepalive_timeout 65;
}
```

### Configuración Default (default.conf)

**Upstreams:**
```nginx
upstream odoo {
    server odoo:8069;
}

upstream odoo-chat {
    server odoo:8072;
}
```

**Server Block:**
```nginx
server {
    listen 80;

    # Proxy a Odoo
    location / {
        proxy_pass http://odoo;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket para chat
    location /websocket {
        proxy_pass http://odoo-chat;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Cache de estáticos (10 días)
    location /web/static/ {
        proxy_cache_valid 200 864000s;  # 10 días
        proxy_buffering on;
        expires 864000s;
    }
}
```

### Headers de Seguridad

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
```

---

## 4. Nginx-Proxy

### Información General

- **Imagen:** `nginxproxy/nginx-proxy:1.4.0`
- **Container Name:** nginx-proxy
- **Función:** Routing automático basado en VIRTUAL_HOST

### Puertos

- **80:** HTTP
- **443:** HTTPS

### Recursos

**Límites:**
- CPU: 0.5 core
- RAM: 256 MB

### Volúmenes

```yaml
volumes:
  - /var/run/docker.sock:/tmp/docker.sock:ro  # Docker API
  - certs:/etc/nginx/certs:ro                  # Certificados SSL
  - vhost:/etc/nginx/vhost.d
  - html:/usr/share/nginx/html
  - ./nginx-proxy/nginx.conf:/etc/nginx/nginx.conf:ro
  - ./nginx-proxy/cors.conf:/etc/nginx/vhost.d/default_location:ro
```

### Variables de Entorno

```env
DEFAULT_HOST=${DOMAIN}
TRUST_DOWNSTREAM_PROXY=true
```

### Características

1. **Auto-Discovery:** Lee labels de contenedores para configurar virtual hosts
2. **SSL Termination:** Maneja certificados SSL/TLS
3. **WebSocket Support:** Proxy de conexiones WebSocket
4. **CORS:** Configuración CORS personalizable

### Funcionamiento

```
Internet → Nginx-Proxy (lee VIRTUAL_HOST) → Nginx → Odoo
                         (lee LETSENCRYPT_HOST) → ACME Companion
```

---

## 5. Let's Encrypt (ACME Companion)

### Información General

- **Imagen:** `nginxproxy/acme-companion:2.2.9`
- **Container Name:** letsencrypt
- **Función:** Auto-renovación de certificados SSL

### Volúmenes

```yaml
volumes:
  - certs:/etc/nginx/certs:rw
  - vhost:/etc/nginx/vhost.d
  - html:/usr/share/nginx/html
  - acme:/etc/acme.sh
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

### Variables de Entorno

```env
DEFAULT_EMAIL=${LETSENCRYPT_EMAIL}
NGINX_PROXY_CONTAINER=nginx-proxy
ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory  # Desarrollo
# ACME_CA_URI=https://acme-v02.api.letsencrypt.org/directory       # Producción
```

### Funcionamiento

1. Lee labels `LETSENCRYPT_HOST` y `LETSENCRYPT_EMAIL`
2. Solicita certificado a Let's Encrypt
3. Valida dominio mediante challenge HTTP-01
4. Instala certificado en Nginx-Proxy
5. Renueva automáticamente cada 60 días

### Staging vs Production

- **Staging:** Rate limit 30 certificados/dominio/semana
- **Production:** Rate limit 50 certificados/dominio/semana

---

## 6. Redis/KeyDB

### Información General

- **Imagen Base:** `eqalpha/keydb:latest`
- **Imagen Custom:** Build desde `redis/Dockerfile`
- **Container Name:** redis
- **Tipo:** KeyDB (fork multi-threaded de Redis)

### Puerto

- **6379:** Puerto estándar Redis

### Recursos

**Límites:**
- CPU: 0.5 core
- RAM: 512 MB

### Volúmenes

```yaml
volumes:
  - redis-data:/data
  - ./redis/keydb.conf:/etc/keydb/keydb.conf:ro
```

### Variables de Entorno

```env
REDIS_PASSWORD=password
REDIS_THREADS=4
REDIS_MAXMEMORY=384mb
```

### Configuración (keydb.conf)

```conf
# Threading
server-threads 4

# Memoria
maxmemory 384mb
maxmemory-policy allkeys-lru

# Persistencia
save 900 1
save 300 10
save 60 10000

# Seguridad
requirepass password

# Red
bind 0.0.0.0
port 6379

# Performance
tcp-backlog 511
timeout 0
tcp-keepalive 300
```

### Uso en Odoo

1. **Sessions:** Almacenamiento de sesiones de usuario
2. **Cache:** Cache de datos frecuentes
3. **Queue:** Cola de jobs asíncronos (opcional)

### Comandos Útiles

```bash
# Conectar a Redis
docker-compose exec redis keydb-cli -a password

# Comandos KeyDB/Redis
INFO                # Información del servidor
DBSIZE              # Número de keys
KEYS *              # Listar todas las keys (no usar en producción)
GET key             # Obtener valor
DEL key             # Eliminar key
FLUSHALL            # Limpiar todo (¡cuidado!)
```

---

## 7. MinIO (S3)

### Información General

- **Imagen:** `minio/minio:latest`
- **Container Name:** s3
- **Función:** Object Storage compatible con S3

### Puertos

- **9000:** API S3
- **9001:** Consola Web

### Recursos

**Límites:**
- CPU: 0.5 core
- RAM: 512 MB

### Volúmenes

```yaml
volumes:
  - s3-data:/data
```

### Variables de Entorno

```env
MINIO_ROOT_USER=myaccesskey
MINIO_ROOT_PASSWORD=mysecretkey
MINIO_BROWSER_REDIRECT_URL=http://s3-console.domain.com
```

### Comando

```bash
server /data --console-address ":9001"
```

### Configuración en Odoo

```env
# Variables .env
AWS_HOST=http://s3:9000
AWS_ACCESS_KEY_ID=myaccesskey
AWS_SECRET_ACCESS_KEY=mysecretkey
AWS_BUCKETNAME=odoocker-{db}
```

### Uso

1. **Filestore:** Almacenamiento de adjuntos de Odoo
2. **Backups:** Almacenamiento de backups
3. **Reports:** PDFs generados temporalmente

### Acceso Web

- URL: `http://localhost:9001`
- User: `myaccesskey`
- Pass: `mysecretkey`

---

## 8. PgAdmin

### Información General

- **Imagen:** `dpage/pgadmin4:8.11`
- **Container Name:** pgadmin
- **Función:** Administración gráfica de PostgreSQL

### Puerto

- **80:** Interfaz Web (a través de nginx-proxy)

### Recursos

**Límites:**
- CPU: 0.5 core
- RAM: 512 MB

### Volúmenes

```yaml
volumes:
  - pgadmin-data:/var/lib/pgadmin
```

### Variables de Entorno

```env
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=admin
PGADMIN_CONFIG_SERVER_MODE=False
VIRTUAL_HOST=pgadmin.${DOMAIN}
LETSENCRYPT_HOST=pgadmin.${DOMAIN}
```

### Configuración

**Conexión a PostgreSQL:**
- Host: `postgres`
- Port: `5432`
- User: `odoo`
- Password: `odoo`
- Database: `postgres` (o nombre específico)

### Activación

```env
# En .env
USE_PGADMIN=true
SERVICES=odoo,nginx,proxy,postgres,pgadmin
```

---

## Dependencias entre Servicios

```
letsencrypt → nginx-proxy → nginx → odoo → postgres
                                        ↓
                                      redis
                                        ↓
                                       s3
postgres ← pgadmin
```

**Orden de inicio:**
1. postgres
2. redis, s3 (paralelo)
3. odoo
4. nginx
5. nginx-proxy
6. letsencrypt
7. pgadmin

---

## Comandos de Gestión

### Iniciar todos los servicios
```bash
docker-compose up -d
```

### Ver logs de un servicio
```bash
docker-compose logs -f odoo
docker-compose logs -f postgres
docker-compose logs -f nginx
```

### Reiniciar un servicio
```bash
docker-compose restart odoo
docker-compose restart postgres
```

### Rebuild de un servicio
```bash
docker-compose build odoo --no-cache
docker-compose up -d --no-deps odoo
```

### Acceder a un contenedor
```bash
docker-compose exec odoo bash
docker-compose exec postgres bash
docker-compose exec -it redis keydb-cli -a password
```

### Detener todos los servicios
```bash
docker-compose down
```

### Detener y eliminar volúmenes (¡CUIDADO!)
```bash
docker-compose down -v
```

---

*Última actualización: 2025-10-27*
