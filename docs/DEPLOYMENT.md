# Deployment y Ambientes

Este documento describe cómo realizar deployment en diferentes ambientes y las características de cada uno.

## Tabla de Contenidos

1. [Ambientes Disponibles](#ambientes-disponibles)
2. [Fresh/Restore](#1-freshrestore)
3. [Local Development](#2-local-development)
4. [Debug](#3-debug)
5. [Testing](#4-testing)
6. [Full](#5-full)
7. [Staging](#6-staging)
8. [Production](#7-production)
9. [Migración entre Ambientes](#migración-entre-ambientes)
10. [Troubleshooting](#troubleshooting)

---

## Ambientes Disponibles

El proyecto soporta 7 ambientes configurables mediante la variable `APP_ENV`:

| Ambiente | Uso | Workers | Demo Data | Dev Mode | SSL |
|----------|-----|---------|-----------|----------|-----|
| **fresh** | Instalación nueva | 0 | ✅ | ❌ | ❌ |
| **restore** | Restaurar backup | 0 | ❌ | ❌ | ❌ |
| **local** | Desarrollo local | 0-3 | ✅ | ✅ | ❌ |
| **debug** | Debugging | 0 | ✅ | ✅ | ❌ |
| **testing** | Tests automatizados | 0 | ❌ | ❌ | ❌ |
| **full** | Réplica producción | 3-9 | ❌ | ❌ | ❌ |
| **staging** | Pre-producción | 3-9 | ❌ | ❌ | ✅ |
| **production** | Producción | 9-13+ | ❌ | ❌ | ✅ |

---

## 1. Fresh/Restore

### Descripción

Ambiente para instalación nueva o restauración de backup.

### Características

- **Sin base de datos** por defecto
- Workers: 0 (modo single-process)
- Timeouts extendidos (3600s CPU, 7200s real)
- Demo data según configuración
- Sin optimizaciones de producción

### Configuración

```env
# .env
APP_ENV=fresh           # o restore
DB_NAME=                # Vacío = sin BD por defecto
INIT=base,web           # Módulos a instalar
LOAD_LANGUAGE=es_PE     # Opcional
WITHOUT_DEMO=           # Vacío = con demo data
```

### Uso: Instalación Nueva

```bash
# 1. Configurar .env
APP_ENV=fresh
DB_NAME=my_new_database
INIT=base,web,sale,purchase,l10n_pe
LOAD_LANGUAGE=es_PE

# 2. Iniciar
docker-compose up -d --build

# 3. Ver logs
docker-compose logs -f odoo

# 4. Acceder
# http://localhost:8069
# Crear BD en interfaz web con nombre: my_new_database
```

### Uso: Restaurar Backup

```bash
# 1. Copiar backup a postgres
docker cp backup.dump equilux_postgres:/tmp/

# 2. Restaurar
docker-compose exec postgres bash
pg_restore -U odoo -d postgres -c /tmp/backup.dump

# 3. Configurar .env
APP_ENV=restore
DB_NAME=my_restored_db

# 4. Iniciar
docker-compose up -d --build
```

---

## 2. Local Development

### Descripción

Ambiente para desarrollo local con hot-reload.

### Características

- Workers: 0-3 (configurable)
- Hot-reload de código Python y XML
- Demo data habilitado
- Dev mode activo
- Logs en nivel DEBUG

### Configuración

```env
# .env
APP_ENV=local
DB_NAME=my_dev_db
WORKERS=0                       # 0 para hot-reload, 3 para testing workers
DEV_MODE=reload,qweb            # Hot-reload
LOG_LEVEL=debug
LIST_DB=True
WITHOUT_DEMO=                   # Vacío = con demo data
```

### Iniciar

```bash
# Método 1: Docker Compose
docker-compose up -d --build
docker-compose logs -f odoo

# Método 2: Con alias (ver setup-alias.sh)
deploy

# Logs
logs
```

### Hot-Reload

Con `DEV_MODE=reload,qweb`, Odoo detecta cambios en:

- **Python (.py):** Recarga automática
- **XML/QWeb (.xml):** Recarga automática
- **CSS/JS:** Requiere refrescar navegador

**Nota:** Hot-reload solo funciona con `WORKERS=0`.

---

## 3. Debug

### Descripción

Ambiente para debugging con VSCode o PyCharm.

### Características

- Workers: 0 (requerido para debugpy)
- Puerto 8070 para debugpy
- Breakpoints en custom-addons
- Compatible con VSCode

### Configuración

```env
# .env
APP_ENV=debug
DB_NAME=my_dev_db
WORKERS=0                       # Requerido
LOG_LEVEL=debug
```

### Configuración VSCode

El archivo `.vscode/launch.json` ya está configurado:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Odoo: Attach",
      "type": "debugpy",
      "request": "attach",
      "connect": {
        "host": "localhost",
        "port": 8070
      },
      "pathMappings": [
        {
          "localRoot": "${workspaceFolder}/odoo/custom-addons",
          "remoteRoot": "/usr/lib/python3/dist-packages/odoo/custom-addons"
        }
      ]
    }
  ]
}
```

### Uso

```bash
# 1. Iniciar en modo debug
APP_ENV=debug docker-compose up -d --build

# 2. En VSCode: F5 para conectar

# 3. Colocar breakpoints en custom-addons

# 4. Ejecutar acción en Odoo → breakpoint se activa
```

---

## 4. Testing

### Descripción

Ambiente para ejecutar tests automatizados.

### Características

- Crea BD con prefijo `test_`
- Instala solo módulos especificados
- Ejecuta tests y termina
- Workers: 0
- Sin demo data

### Configuración

```env
# .env
APP_ENV=testing
DB_NAME=my_test_db              # Se creará test_my_test_db
ADDONS_TO_TEST=my_addon         # Módulo a testear
TEST_TAGS=/my_addon             # Tags de test
TEST_ENABLE=True
WORKERS=0
```

### Uso

```bash
# 1. Configurar .env
APP_ENV=testing
ADDONS_TO_TEST=sale,purchase
TEST_TAGS=/sale/tests/test_sale_order

# 2. Ejecutar tests
docker-compose up -d

# 3. Ver resultados
docker-compose logs odoo

# 4. BD test_* se mantiene para inspección
```

### Test Manual

```bash
docker-compose exec odoo bash

odoo \
  --config /etc/odoo/odoo.conf \
  --database=test_mydb \
  --test-enable \
  --test-tags /my_module \
  --init=my_module \
  --workers=0 \
  --stop-after-init
```

---

## 5. Full

### Descripción

Instalación completa de todos los módulos, réplica de producción.

### Características

- Instala módulos según `INIT`
- Workers según configuración
- Sin demo data
- Útil para testing pre-staging

### Configuración

```env
# .env
APP_ENV=full
DB_NAME=my_full_db
INIT=base,web,sale,purchase,l10n_pe_edi_doc,l10n_pe_accounting
WORKERS=3
WITHOUT_DEMO=all
LOG_LEVEL=info
```

### Uso

```bash
# Instalación completa desde cero
docker-compose up -d --build
docker-compose logs -f odoo
```

---

## 6. Staging

### Descripción

Ambiente de pre-producción para validar cambios antes de producción.

### Características

- Actualiza todos los módulos (`UPDATE=all`)
- Instala nuevos según `INIT`
- Workers según CPU
- Sin demo data
- SSL con Let's Encrypt staging
- Timeouts extendidos

### Configuración

```env
# .env
APP_ENV=staging
DB_NAME=my_staging_db
UPDATE=all                      # Actualiza todo
INIT=                           # Nuevos módulos a instalar
WORKERS=3
WITHOUT_DEMO=all
LOG_LEVEL=info
LIST_DB=True

# SSL Staging
LETSENCRYPT_HOST=staging.domain.com
LETSENCRYPT_EMAIL=admin@domain.com
ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory

# Servicios
USE_REDIS=true
USE_S3=true
USE_SENTRY=true
SENTRY_ENVIRONMENT=staging
```

### Uso

```bash
# 1. Configurar .env para staging
# 2. Copiar docker-compose.override.yml para staging
cp docker-compose.override.production.yml docker-compose.override.yml

# 3. Deploy
docker-compose down
git pull
docker-compose build --no-cache
docker-compose up -d

# 4. Verificar
docker-compose logs -f odoo
```

---

## 7. Production

### Descripción

Ambiente de producción optimizado.

### Características

- Sin demo data (`WITHOUT_DEMO=all`)
- Dev mode deshabilitado
- Workers: CPU*2+1 (9-13+)
- SSL con Let's Encrypt production
- Logging en nivel WARN
- Filtro de BD por dominio
- Todos los servicios activados

### Configuración

```env
# .env
APP_ENV=production
DB_NAME=my_production_db
WORKERS=13                      # Ajustar según CPU
MAX_CRON_THREADS=4
WITHOUT_DEMO=all
DEV_MODE=
LOG_LEVEL=warn
LIST_DB=False                   # ¡Importante!
DBFILTER=^%h$                   # Filtrar por hostname

# Límites de Recursos
LIMIT_MEMORY_HARD=4294967296    # 4GB
LIMIT_MEMORY_SOFT=3221225472    # 3GB
LIMIT_TIME_CPU=600
LIMIT_TIME_REAL=1200

# SSL Production
DOMAIN=erp.domain.com
LETSENCRYPT_HOST=${DOMAIN}
LETSENCRYPT_EMAIL=admin@domain.com
ACME_CA_URI=https://acme-v02.api.letsencrypt.org/directory  # Production!

# Servicios
USE_REDIS=true
USE_S3=true
USE_SENTRY=true
USE_PGADMIN=false               # Desactivar en producción
SENTRY_ENVIRONMENT=production

# SMTP
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@domain.com
SMTP_PASSWORD=mypassword
SMTP_TLS=True
EMAIL_FROM=noreply@domain.com
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
    restart: always

  postgres:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
    restart: always

  nginx:
    restart: always

  nginx-proxy:
    restart: always

  letsencrypt:
    restart: always

  redis:
    restart: always

  s3:
    restart: always
```

### Deployment a Producción

```bash
# 1. Backup de BD actual
docker-compose exec postgres pg_dump -U odoo -F c my_production_db > backup_$(date +%Y%m%d_%H%M%S).dump

# 2. Backup de filestore
docker run --rm -v equilux_odoo-data:/data -v $(pwd):/backup ubuntu tar czf /backup/filestore_$(date +%Y%m%d_%H%M%S).tar.gz /data

# 3. Configurar .env para producción
nano .env
# Cambiar APP_ENV=production
# Ajustar WORKERS, DOMAIN, etc.

# 4. Copiar override de producción
cp docker-compose.override.production.yml docker-compose.override.yml

# 5. Pull últimos cambios
git pull

# 6. Build y deploy
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 7. Verificar logs
docker-compose logs -f --tail 200 odoo

# 8. Verificar servicios
docker-compose ps

# 9. Verificar SSL
curl -I https://erp.domain.com

# 10. Test de smoke
# - Login
# - Crear registro
# - Generar reporte
```

### Checklist Pre-Producción

- [ ] Backup de BD y filestore
- [ ] Configurar variables `.env` para producción
- [ ] Establecer `LIST_DB=False` y `DBFILTER=^%h$`
- [ ] Configurar SMTP correctamente
- [ ] Activar `USE_REDIS=true` y `USE_S3=true`
- [ ] Configurar Sentry con DSN de producción
- [ ] Verificar certificado SSL (ACME_CA_URI production)
- [ ] Configurar `docker-compose.override.yml` para producción
- [ ] Ajustar WORKERS según CPU disponible
- [ ] Desactivar `USE_PGADMIN` (seguridad)
- [ ] Configurar firewall (solo 80/443)
- [ ] Configurar monitoreo y alertas
- [ ] Documentar credenciales en lugar seguro

---

## Migración entre Ambientes

### De Local a Staging

```bash
# 1. Dump de BD local
docker-compose exec postgres pg_dump -U odoo -F c my_dev_db > dev_backup.dump

# 2. Copiar a staging
scp dev_backup.dump user@staging-server:/tmp/

# 3. En staging: restaurar
docker cp /tmp/dev_backup.dump equilux_postgres:/tmp/
docker-compose exec postgres pg_restore -U odoo -d my_staging_db -c /tmp/dev_backup.dump

# 4. Copiar filestore
docker run --rm -v equilux_odoo-data:/data -v $(pwd):/backup ubuntu tar czf /backup/filestore.tar.gz /data
scp filestore.tar.gz user@staging-server:/tmp/

# 5. En staging: restaurar filestore
docker run --rm -v equilux_odoo-data:/data -v /tmp:/backup ubuntu tar xzf /backup/filestore.tar.gz -C /

# 6. Configurar .env para staging
APP_ENV=staging
DB_NAME=my_staging_db

# 7. Deploy
docker-compose down && docker-compose up -d --build
```

### De Staging a Production

```bash
# Similar a local→staging, pero:
# - Verificar checklist pre-producción
# - Backup de producción antes de sobrescribir
# - Window de mantenimiento programado
# - Comunicar a usuarios
# - Rollback plan preparado
```

---

## Troubleshooting

### Problema: Odoo no inicia

```bash
# Ver logs
docker-compose logs odoo

# Errores comunes:
# 1. BD no existe → crear BD
# 2. Módulo no encontrado → verificar ADDONS_PATH
# 3. Error de dependencias → pip install -r requirements.txt
```

### Problema: Workers no inician

```bash
# Verificar recursos disponibles
docker stats

# Reducir WORKERS en .env
WORKERS=3

# Reiniciar
docker-compose restart odoo
```

### Problema: SSL no funciona

```bash
# Verificar logs de letsencrypt
docker-compose logs letsencrypt

# Causas comunes:
# 1. ACME_CA_URI incorrecto
# 2. Puerto 80/443 no accesible
# 3. Dominio no apunta a servidor
# 4. Rate limit de Let's Encrypt

# Usar staging primero
ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory
```

### Problema: Performance lenta

```bash
# 1. Aumentar workers
WORKERS=9  # CPU*2+1

# 2. Activar Redis
USE_REDIS=true
SESSION_REDIS=true

# 3. Aumentar recursos de PostgreSQL
# En docker-compose.override.yml:
# shared_buffers=2GB
# effective_cache_size=4GB

# 4. Activar S3 para filestore
USE_S3=true
```

### Problema: Error 502 Bad Gateway

```bash
# 1. Verificar Odoo está corriendo
docker-compose ps odoo

# 2. Verificar nginx puede conectar
docker-compose exec nginx curl http://odoo:8069

# 3. Aumentar timeouts en nginx/default.conf
proxy_connect_timeout 600s;
proxy_send_timeout 600s;
proxy_read_timeout 600s;
```

### Comandos Útiles

```bash
# Ver estado de servicios
docker-compose ps

# Ver uso de recursos
docker stats

# Reiniciar servicio específico
docker-compose restart odoo

# Rebuild completo
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f --tail 200 odoo

# Acceder a contenedor
docker-compose exec odoo bash
docker-compose exec postgres bash

# Ejecutar comando en contenedor
docker-compose exec odoo odoo shell -d mydb --http-port=8071
```

---

*Última actualización: 2025-10-27*
