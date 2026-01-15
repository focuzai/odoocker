# Configuración

Este documento detalla todas las variables de entorno, archivos de configuración y opciones disponibles en el proyecto.

## Tabla de Contenidos

1. [Variables de Entorno (.env)](#variables-de-entorno-env)
2. [Configuración de Odoo (odoo.conf)](#configuración-de-odoo-odooconf)
3. [Configuración de Nginx](#configuración-de-nginx)
4. [Configuración de Redis/KeyDB](#configuración-de-rediskeydb)
5. [Docker Compose Overrides](#docker-compose-overrides)

---

## Variables de Entorno (.env)

### 1. Configuración General de Odoo

```env
# Ambiente de ejecución
APP_ENV=local                    # fresh|local|debug|testing|full|staging|production

# Módulos
INIT=                           # Módulos a instalar (separados por coma)
UPDATE=                         # Módulos a actualizar (separados por coma, o 'all')
LOAD=base,web                   # Módulos base a cargar en startup

# Paths
ROOT_PATH=/usr/lib/python3/dist-packages/odoo
ADDONS_PATH=${ROOT_PATH}/addons,${ROOT_PATH}/extra-addons,${ROOT_PATH}/custom-addons

# Workers y Performance
WORKERS=0                       # 0 = sin workers (desarrollo), CPU*2+1 (producción)
MAX_CRON_THREADS=2              # Threads para cron jobs
LIMIT_MEMORY_HARD=2684354560    # 2.5 GB hard limit
LIMIT_MEMORY_SOFT=2147483648    # 2 GB soft limit
LIMIT_TIME_CPU=600              # Timeout CPU (segundos)
LIMIT_TIME_REAL=1200            # Timeout real (segundos)

# Admin
ADMIN_PASSWD=odoo               # Contraseña maestra de Odoo
DOMAIN=erp.odoocker.test        # Dominio principal

# Desarrollo
DEV_MODE=                       # reload,qweb para hot-reload
WITHOUT_DEMO=                   # all para deshabilitar data demo
```

### 2. Servicios Activados

```env
# Servicios a iniciar (separados por coma)
SERVICES=odoo,nginx,proxy,postgres

# Servicios opcionales
USE_REDIS=false                 # Activar Redis para sessions
USE_S3=false                    # Activar MinIO para storage
USE_SENTRY=false                # Activar Sentry para error tracking
USE_PGADMIN=false               # Activar PgAdmin

# Actualizar SERVICES cuando actives servicios:
# SERVICES=odoo,nginx,proxy,postgres,redis,s3,pgadmin
```

### 3. Base de Datos (PostgreSQL)

```env
# Conexión
DB_HOST=postgres
DB_PORT=5432
DB_NAME=                        # Nombre de la BD (vacío = sin BD por defecto)
DB_USER=odoo
DB_PASSWORD=odoo

# Configuración
DB_TEMPLATE=unaccent_template   # Template para nuevas BD
UNACCENT=False                  # Usar extensión unaccent
LIST_DB=True                    # Permitir listar bases de datos
DBFILTER=.*                     # Regex para filtrar BD por dominio
DB_SSLMODE=prefer               # disable|allow|prefer|require|verify-ca|verify-full
DB_MAXCONN=64                   # Máximo de conexiones

# Idioma
LOAD_LANGUAGE=                  # es_PE para español Perú
```

### 4. Redis (Sessions y Cache)

```env
# Activación
SESSION_REDIS=true              # Usar Redis para sessions

# Conexión
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=password
REDIS_URL=redis://odoo:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/0

# Configuración
REDIS_THREADS=4                 # Threads de KeyDB
REDIS_MAXMEMORY=384mb           # Memoria máxima
REDIS_EXPIRATION=604800         # 7 días (usuarios autenticados)
REDIS_EXPIRATION_ANONYMOUS=10800 # 3 horas (usuarios anónimos)
```

### 5. S3 / MinIO (Object Storage)

```env
# Activación
AWS_HOST=http://s3:9000         # URL de MinIO
AWS_REGION=us-east-1            # Región (para AWS real)

# Credenciales
AWS_ACCESS_KEY_ID=myaccesskey
AWS_SECRET_ACCESS_KEY=mysecretkey

# Bucket
AWS_BUCKETNAME=odoocker-{db}    # {db} se reemplaza por nombre de BD
```

### 6. Nginx y SSL

```env
# Dominios
DOMAIN=erp.odoocker.test
DOMAIN0=${DOMAIN}
DOMAIN1=                        # Dominio adicional 1
DOMAIN2=                        # Dominio adicional 2

# Virtual Host (usado por nginx-proxy)
VIRTUAL_HOST=${DOMAIN}
VIRTUAL_PORT=80

# Let's Encrypt
LETSENCRYPT_HOST=${DOMAIN}
LETSENCRYPT_EMAIL=mail@example.com
ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory  # Staging
# ACME_CA_URI=https://acme-v02.api.letsencrypt.org/directory        # Production

# CORS
CORS_ALLOWED_DOMAIN="'http://external-domain.test'"
```

### 7. Sentry (Error Tracking)

```env
# Activación
SENTRY_DSN=                     # DSN de Sentry
SENTRY_ENABLED=true
SENTRY_LOGGING_LEVEL=warn       # debug|info|warn|error
SENTRY_ENVIRONMENT=production   # Nombre del ambiente en Sentry
SENTRY_RELEASE=                 # Versión/release
```

### 8. SMTP (Email)

```env
SMTP_SERVER=                    # smtp.gmail.com
SMTP_PORT=25                    # 587 para TLS, 465 para SSL
SMTP_USER=                      # Usuario SMTP
SMTP_PASSWORD=                  # Contraseña SMTP
SMTP_SSL=False                  # True para SSL
SMTP_TLS=False                  # True para TLS
EMAIL_FROM=                     # Email remitente por defecto
```

### 9. Logging

```env
LOG_LEVEL=info                  # debug|info|warn|error|critical
LOG_HANDLER_LEVEL=INFO          # Nivel de logs en consola
LOGFILE=                        # Path a archivo de log (vacío = solo consola)
```

### 10. Testing

```env
# Solo para APP_ENV=testing
TEST_ENABLE=True
TEST_TAGS=                      # Tags de tests a ejecutar (/module_name)
ADDONS_TO_TEST=                 # Módulos a testear
TEST_FILE=                      # Archivo específico de test
```

### 11. GitHub (para clonar repos privados)

```env
# Usuario y token
GITHUB_USER=
GITHUB_ACCESS_TOKEN=

# Enterprise (si usas Odoo Enterprise)
ENTERPRISE_USER=
ENTERPRISE_ACCESS_TOKEN=
```

### 12. PgAdmin

```env
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=admin
PGADMIN_CONFIG_SERVER_MODE=False
```

---

## Configuración de Odoo (odoo.conf)

El archivo `odoo/odoo.conf` se genera automáticamente desde las variables `.env` usando el script `odoorc.sh`.

### Secciones Principales

```ini
[options]
# HTTP
http_port = 8069
http_interface = 0.0.0.0
proxy_mode = True

# Database
db_host = postgres
db_port = 5432
db_user = odoo
db_password = odoo
db_name = False
db_template = unaccent_template
db_maxconn = 64
list_db = True
dbfilter = .*

# Addons
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/usr/lib/python3/dist-packages/odoo/extra-addons,/usr/lib/python3/dist-packages/odoo/custom-addons

# Workers
workers = 0
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_time_cpu = 600
limit_time_real = 1200

# Logging
log_level = info
log_handler = :INFO

# Admin
admin_passwd = odoo

# SMTP
smtp_server =
smtp_port = 25
smtp_user =
smtp_password =
smtp_ssl = False
email_from =

# Dev Mode
dev_mode =
```

### Regenerar odoo.conf

```bash
# Acceder al contenedor
docker-compose exec odoo bash

# Ejecutar script
chmod +x /usr/lib/python3/dist-packages/odoo/odoorc.sh
/usr/lib/python3/dist-packages/odoo/odoorc.sh

# Reiniciar Odoo
docker-compose restart odoo
```

---

## Configuración de Nginx

### nginx/nginx.conf

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Log Format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'upstream: $upstream_response_time';

    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 2G;

    # Compression Brotli
    brotli on;
    brotli_comp_level 6;
    brotli_types text/plain text/css text/xml text/javascript
                 application/json application/javascript application/xml+rss;

    # Compression Gzip (fallback)
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss;

    include /etc/nginx/conf.d/*.conf;
}
```

### nginx/default.conf

**Modificar según necesidad:**

```nginx
# Upstreams
upstream odoo {
    server odoo:8069;
}

upstream odoo-chat {
    server odoo:8072;
}

# Rate Limiting (opcional)
limit_req_zone $binary_remote_addr zone=odoo_limit:10m rate=10r/s;

server {
    listen 80;
    server_name _;

    # Rate limiting
    # limit_req zone=odoo_limit burst=20 nodelay;

    # Proxy a Odoo
    location / {
        proxy_pass http://odoo;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;

        # Timeouts
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }

    # WebSocket
    location /websocket {
        proxy_pass http://odoo-chat;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    # Static Files (cache 10 días)
    location /web/static/ {
        proxy_cache_valid 200 864000s;
        proxy_buffering on;
        expires 864000s;
        proxy_pass http://odoo;
    }

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

---

## Configuración de Redis/KeyDB

### redis/keydb.conf

Generado por `redis/keydb.sh` desde variables `.env`.

```conf
# Networking
bind 0.0.0.0
port 6379
protected-mode yes
requirepass password

# Threading (KeyDB específico)
server-threads 4

# Memory
maxmemory 384mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
dir /data
dbfilename dump.rdb

# Performance
tcp-backlog 511
timeout 0
tcp-keepalive 300
databases 16

# Logging
loglevel notice
```

### Políticas de Eviction

| Política | Descripción |
|----------|-------------|
| `noeviction` | No eliminar, retornar error cuando memoria llena |
| `allkeys-lru` | **Recomendado**: Elimina keys menos usadas |
| `allkeys-lfu` | Elimina keys menos frecuentemente usadas |
| `volatile-lru` | Elimina keys con TTL, menos usadas |
| `volatile-ttl` | Elimina keys con TTL más corto |

---

## Docker Compose Overrides

### docker-compose.override.yml (Local/Development)

```yaml
services:
  odoo:
    deploy:
      resources:
        limits:
          cpus: '3'
          memory: 6G
        reservations:
          cpus: '1'
          memory: 4G
    environment:
      - WORKERS=3
      - DEV_MODE=reload,qweb
      - LOG_LEVEL=debug

  postgres:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
    command:
      - postgres
      - -c
      - shared_buffers=1GB
      - -c
      - effective_cache_size=2GB
```

### docker-compose.override.production.yml

```yaml
services:
  odoo:
    deploy:
      resources:
        limits:
          cpus: '6'
          memory: 12G
        reservations:
          cpus: '2'
          memory: 8G
    environment:
      - WORKERS=13              # CPU*2+1 = 6*2+1 = 13
      - MAX_CRON_THREADS=4
      - LIMIT_MEMORY_HARD=4294967296   # 4GB
      - LIMIT_MEMORY_SOFT=3221225472   # 3GB
      - DEV_MODE=
      - LOG_LEVEL=warn
      - WITHOUT_DEMO=all
    restart: always

  postgres:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
    command:
      - postgres
      - -c
      - shared_buffers=2GB
      - -c
      - effective_cache_size=4GB
      - -c
      - max_connections=200
    restart: always

  nginx:
    restart: always

  nginx-proxy:
    restart: always

  letsencrypt:
    environment:
      - ACME_CA_URI=https://acme-v02.api.letsencrypt.org/directory  # Production!
    restart: always
```

---

## Configuración Recomendada por Ambiente

### Desarrollo Local

```env
APP_ENV=local
WORKERS=0
DEV_MODE=reload,qweb
LOG_LEVEL=debug
LIST_DB=True
WITHOUT_DEMO=
USE_REDIS=false
USE_S3=false
USE_SENTRY=false
```

### Staging

```env
APP_ENV=staging
WORKERS=3
DEV_MODE=
LOG_LEVEL=info
LIST_DB=True
WITHOUT_DEMO=all
USE_REDIS=true
USE_S3=true
USE_SENTRY=true
SENTRY_ENVIRONMENT=staging
```

### Producción

```env
APP_ENV=production
WORKERS=13              # Ajustar según CPU
DEV_MODE=
LOG_LEVEL=warn
LIST_DB=False           # ¡Importante!
DBFILTER=^%h$           # Filtrar por host
WITHOUT_DEMO=all
USE_REDIS=true
USE_S3=true
USE_SENTRY=true
SENTRY_ENVIRONMENT=production
ACME_CA_URI=https://acme-v02.api.letsencrypt.org/directory
```

---

## Variables de Entorno Avanzadas

### Límites de Recursos

```env
# Memory Limits
LIMIT_MEMORY_HARD=2684354560    # 2.5 GB
LIMIT_MEMORY_SOFT=2147483648    # 2 GB
LIMIT_REQUEST=8192              # Límite de requests

# Time Limits
LIMIT_TIME_CPU=600              # Timeout CPU
LIMIT_TIME_REAL=1200            # Timeout real
LIMIT_TIME_REAL_CRON=300        # Timeout para cron jobs

# Connections
DB_MAXCONN=64                   # Pool de conexiones BD
MAX_CRON_THREADS=2              # Threads de cron
```

### Debugging

```env
# Enable debugging
APP_ENV=debug
DEBUGPY_ENABLE=True
DEBUGPY_PORT=8070

# En VSCode: F5 para conectar al puerto 8070
```

### Gevent (WebSocket)

```env
GEVENT_PORT=8072
CHANNEL_IMPL=gevent
```

---

*Última actualización: 2025-10-27*
