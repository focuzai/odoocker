# Scripts y Comandos

Documentación completa de todos los scripts disponibles y alias configurables en el proyecto.

## Tabla de Contenidos

1. [Scripts Principales](#scripts-principales)
2. [Alias Configurables](#alias-configurables)
3. [Comandos Docker Compose](#comandos-docker-compose)
4. [Comandos Odoo](#comandos-odoo)
5. [Comandos PostgreSQL](#comandos-postgresql)
6. [Comandos Redis](#comandos-redis)
7. [Comandos Git](#comandos-git)

---

## Scripts Principales

### 1. setup-alias.sh

**Ubicación:** `/setup-alias.sh`

**Descripción:** Configura alias de bash para operaciones frecuentes.

**Uso:**

```bash
chmod +x setup-alias.sh
./setup-alias.sh

# Recargar shell
source ~/.bashrc  # Bash
source ~/.zshrc   # Zsh
```

**Alias creados:**

```bash
alias odoo='cd ~/projects/odoo'
alias hard-deploy='...'
alias deploy='...'
alias odoo-hard='...'
alias odoo-deploy='...'
alias odoo-restart='...'
alias odoo-update='...'
alias psql='...'
alias logs='...'
```

---

### 2. odoo/entrypoint.sh

**Ubicación:** `odoo/entrypoint.sh`

**Descripción:** Punto de entrada del contenedor Odoo. Maneja 7 modos según `APP_ENV`.

**Modos:**

```bash
APP_ENV=fresh       # Instalación nueva
APP_ENV=restore     # Restaurar backup
APP_ENV=local       # Desarrollo local
APP_ENV=debug       # Debugging
APP_ENV=testing     # Tests automatizados
APP_ENV=full        # Instalación completa
APP_ENV=staging     # Pre-producción
APP_ENV=production  # Producción
```

**Ejemplo de uso interno (automático):**

```bash
# No se ejecuta manualmente
# Se ejecuta automáticamente al iniciar contenedor
docker-compose up -d
```

---

### 3. odoo/odoorc.sh

**Ubicación:** `odoo/odoorc.sh`

**Descripción:** Genera `odoo.conf` desde variables de entorno `.env`.

**Uso:**

```bash
# Acceder al contenedor
docker-compose exec odoo bash

# Ejecutar script
chmod +x /usr/lib/python3/dist-packages/odoo/odoorc.sh
/usr/lib/python3/dist-packages/odoo/odoorc.sh

# Reiniciar Odoo para aplicar cambios
exit
docker-compose restart odoo
```

**Variables procesadas:**

- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`
- `WORKERS`, `MAX_CRON_THREADS`
- `ADMIN_PASSWD`
- `SMTP_*`
- `LOG_LEVEL`
- `DEV_MODE`
- Y más...

---

### 4. odoo/clone-addons.sh

**Ubicación:** `odoo/clone-addons.sh`

**Descripción:** Clona repositorios de addons de terceros según `third-party-addons.txt`.

**Configuración:** `odoo/third-party-addons.txt`

```bash
# Formato:
# <public|private> <repo_url> <module1> <condition1> <module2> <condition2>

# Ejemplo:
enterprise https://github.com/focuz-ai/odoo-enterprise true
public https://github.com/OCA/manufacture.git mrp_bom_component_menu true
public https://github.com/odoocker/odoo-cloud-platform.git session_redis ${USE_REDIS}
```

**Uso:**

```bash
# Se ejecuta automáticamente durante build
# Para ejecutar manualmente:

docker-compose exec odoo bash
cd /usr/lib/python3/dist-packages/odoo
chmod +x clone-addons.sh
./clone-addons.sh
```

**Variables de GitHub:**

```env
# En .env
GITHUB_USER=myuser
GITHUB_ACCESS_TOKEN=ghp_xxxxx
ENTERPRISE_USER=myuser
ENTERPRISE_ACCESS_TOKEN=ghp_xxxxx
```

---

### 5. odoo/odoo-update.sh

**Ubicación:** `odoo/odoo-update.sh`

**Descripción:** Actualiza módulos de Odoo en una o múltiples bases de datos.

**Uso:**

```bash
# Método 1: Con alias
odoo-update module_name

# Método 2: Directo
chmod +x odoo/odoo-update.sh
./odoo/odoo-update.sh module_name

# Actualizar múltiples módulos
./odoo/odoo-update.sh module1,module2,module3

# Actualizar todos los módulos
./odoo/odoo-update.sh all
```

**Opciones avanzadas:**

```bash
# Actualizar en BD específica
./odoo/odoo-update.sh module_name --database=my_db

# Actualizar múltiples BD
./odoo/odoo-update.sh module_name --database=db1,db2,db3
```

**Documentación:** `odoo/odoo-update.txt`

---

### 6. postgres/psql.sh

**Ubicación:** `postgres/psql.sh`

**Descripción:** Acceso rápido a psql en el contenedor de PostgreSQL.

**Uso:**

```bash
# Método 1: Con alias
psql

# Método 2: Directo
chmod +x postgres/psql.sh
./postgres/psql.sh
```

**Dentro de psql:**

```sql
-- Listar bases de datos
\l

-- Conectar a BD
\c my_database

-- Listar tablas
\dt

-- Listar usuarios
\du

-- Ejecutar query
SELECT * FROM res_partner LIMIT 5;

-- Salir
\q
```

---

### 7. postgres/entrypoint.sh

**Ubicación:** `postgres/entrypoint.sh`

**Descripción:** Inicialización de PostgreSQL con extensiones y configuración.

**Funciones:**

1. Crea extensión `UNACCENT`
2. Crea usuario `odoo` con privilegios SUPERUSER
3. Crea template database `unaccent_template`
4. Inicializa PgAdmin (si `USE_PGADMIN=true`)

**Uso (automático):**

```bash
# Se ejecuta automáticamente al crear contenedor
docker-compose up -d postgres
```

---

### 8. redis/keydb.sh

**Ubicación:** `redis/keydb.sh`

**Descripción:** Genera configuración de KeyDB desde variables de entorno.

**Variables:**

```env
REDIS_THREADS=4
REDIS_MAXMEMORY=384mb
REDIS_PASSWORD=password
```

**Uso (automático):**

```bash
# Se ejecuta automáticamente durante build
docker-compose build redis
```

---

## Alias Configurables

Después de ejecutar `setup-alias.sh`, tendrás disponibles:

### odoo

**Descripción:** Navega al directorio del proyecto.

**Uso:**

```bash
odoo
# → cd ~/projects/odoo (o ruta configurada)
```

---

### hard-deploy

**Descripción:** Deploy completo con rebuild sin caché.

**Comando:**

```bash
docker compose down && \
git pull && \
docker compose pull && \
docker compose build --no-cache && \
docker compose up -d && \
docker compose logs -f --tail 2000 odoo
```

**Uso:**

```bash
hard-deploy
```

**Cuándo usar:** Cambios en Dockerfile, dependencies, o errores persistentes.

---

### deploy

**Descripción:** Deploy rápido con rebuild y logs.

**Comando:**

```bash
docker compose down && \
git pull && \
docker compose up -d --build && \
docker compose logs -f --tail 2000 odoo
```

**Uso:**

```bash
deploy
```

**Cuándo usar:** Cambios en código, configuración, o actualización de git.

---

### odoo-hard

**Descripción:** Rebuild completo de Odoo sin caché.

**Comando:**

```bash
docker compose build odoo --no-cache && \
docker compose up -d --no-deps --build odoo && \
docker compose logs -f --tail 2000 odoo
```

**Uso:**

```bash
odoo-hard
```

**Cuándo usar:** Cambios en `odoo/Dockerfile`, `requirements.txt`, o errores de build.

---

### odoo-deploy

**Descripción:** Rebuild rápido solo de Odoo.

**Comando:**

```bash
docker compose build odoo && \
docker compose up -d --no-deps --build odoo && \
docker compose logs -f --tail 2000 odoo
```

**Uso:**

```bash
odoo-deploy
```

**Cuándo usar:** Cambios en configuración de Odoo, pero no en dependencies.

---

### odoo-restart

**Descripción:** Reinicia solo el contenedor de Odoo.

**Comando:**

```bash
docker compose restart --no-deps odoo
```

**Uso:**

```bash
odoo-restart
```

**Cuándo usar:** Aplicar cambios en `.env` o `odoo.conf`.

---

### odoo-update

**Descripción:** Ejecuta script de actualización de módulos.

**Comando:**

```bash
chmod +x odoo/odoo-update.sh && \
odoo/odoo-update.sh
```

**Uso:**

```bash
odoo-update module_name
odoo-update module1,module2
odoo-update all
```

---

### psql

**Descripción:** Acceso rápido a psql.

**Comando:**

```bash
chmod +x postgres/psql.sh && \
postgres/psql.sh
```

**Uso:**

```bash
psql
```

---

### logs

**Descripción:** Ver logs de Odoo en tiempo real.

**Comando:**

```bash
docker compose logs -f --tail 2000 odoo
```

**Uso:**

```bash
logs
```

**Parar logs:** `Ctrl+C`

---

## Comandos Docker Compose

### Gestión de Servicios

```bash
# Iniciar todos los servicios
docker-compose up -d

# Iniciar con rebuild
docker-compose up -d --build

# Iniciar servicio específico
docker-compose up -d odoo

# Detener todos los servicios
docker-compose down

# Detener y eliminar volúmenes (¡CUIDADO!)
docker-compose down -v

# Reiniciar todos los servicios
docker-compose restart

# Reiniciar servicio específico
docker-compose restart odoo
```

### Logs

```bash
# Ver logs de todos los servicios
docker-compose logs

# Logs en tiempo real
docker-compose logs -f

# Logs de servicio específico
docker-compose logs odoo
docker-compose logs postgres

# Logs con límite de líneas
docker-compose logs --tail 100 odoo

# Logs con timestamp
docker-compose logs -f -t odoo
```

### Estado y Recursos

```bash
# Ver estado de servicios
docker-compose ps

# Ver recursos (CPU, RAM)
docker stats

# Ver recursos de un servicio
docker stats equilux_odoo

# Inspeccionar contenedor
docker inspect equilux_odoo
```

### Build

```bash
# Build de todos los servicios
docker-compose build

# Build sin caché
docker-compose build --no-cache

# Build de servicio específico
docker-compose build odoo

# Build y iniciar
docker-compose up -d --build
```

### Ejecutar Comandos

```bash
# Bash en contenedor
docker-compose exec odoo bash
docker-compose exec postgres bash

# Comando único
docker-compose exec odoo whoami
docker-compose exec postgres psql -U odoo -l

# Como root
docker-compose exec -u root odoo bash

# Sin TTY (para scripts)
docker-compose exec -T odoo odoo --version
```

---

## Comandos Odoo

### Odoo CLI

```bash
# Acceder al contenedor
docker-compose exec odoo bash

# Versión de Odoo
odoo --version

# Ayuda
odoo --help

# Iniciar Odoo (manual)
odoo -c /etc/odoo/odoo.conf

# Odoo Shell
odoo shell -d my_database --http-port=8071

# Scaffold de addon
odoo scaffold my_addon /usr/lib/python3/dist-packages/odoo/custom-addons

# Instalar módulos
odoo -d my_db -i module1,module2 --stop-after-init

# Actualizar módulos
odoo -d my_db -u module1,module2 --stop-after-init

# Tests
odoo \
  --config /etc/odoo/odoo.conf \
  --database=test_db \
  --test-enable \
  --test-tags /module_name \
  --init=module_name \
  --workers=0 \
  --stop-after-init
```

### Odoo Shell Commands

```python
# Environment
self
self.env
self.env.context

# Buscar
self.env['res.partner'].search([])
self.env['res.partner'].search_count([('is_company', '=', True)])

# Crear
partner = self.env['res.partner'].create({'name': 'Test'})

# Actualizar
partner.write({'email': 'test@example.com'})

# Eliminar
partner.unlink()

# Módulos
self.env['ir.module.module'].search([('name', '=', 'sale')]).button_immediate_install()
self.env['ir.module.module'].search([('name', '=', 'sale')]).button_immediate_upgrade()

# SQL
self.env.cr.execute("SELECT * FROM res_partner LIMIT 5")
self.env.cr.fetchall()

# Commit
self.env.cr.commit()

# Rollback
self.env.cr.rollback()
```

---

## Comandos PostgreSQL

### psql Commands

```bash
# Acceder a psql
./postgres/psql.sh

# O manualmente
docker-compose exec postgres psql -U odoo
```

### Dentro de psql

```sql
-- Listar bases de datos
\l

-- Conectar a BD
\c my_database

-- Listar schemas
\dn

-- Listar tablas
\dt

-- Describir tabla
\d res_partner

-- Listar usuarios
\du

-- Listar roles
\dg

-- Ejecutar query
SELECT * FROM res_partner LIMIT 5;

-- Tamaño de BD
SELECT pg_size_pretty(pg_database_size('my_database'));

-- Tablas más grandes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Conexiones activas
SELECT * FROM pg_stat_activity;

-- Terminar conexión
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'my_database';

-- Vacuum
VACUUM ANALYZE;

-- Salir
\q
```

### Backup y Restore

```bash
# Backup
docker-compose exec postgres pg_dump -U odoo -F c my_database > backup.dump

# Backup con compresión
docker-compose exec postgres pg_dump -U odoo -F c -Z 9 my_database > backup.dump

# Backup solo schema
docker-compose exec postgres pg_dump -U odoo -s my_database > schema.sql

# Restore
docker cp backup.dump equilux_postgres:/tmp/
docker-compose exec postgres pg_restore -U odoo -d my_database -c /tmp/backup.dump

# Restore creando BD
docker-compose exec postgres createdb -U odoo my_new_database
docker-compose exec postgres pg_restore -U odoo -d my_new_database /tmp/backup.dump
```

---

## Comandos Redis

### KeyDB CLI

```bash
# Acceder a KeyDB
docker-compose exec redis keydb-cli -a password

# Sin password (si no está configurado)
docker-compose exec redis keydb-cli
```

### Comandos KeyDB/Redis

```bash
# Info
INFO
INFO memory
INFO stats

# Keys
KEYS *                  # Listar todas (no usar en producción)
DBSIZE                  # Número de keys
RANDOMKEY               # Key aleatoria

# Get/Set
GET session:123
SET mykey "myvalue"
DEL mykey

# Sessions de Odoo
KEYS session:*
GET session:abc123

# TTL
TTL session:abc123      # Tiempo restante
EXPIRE mykey 3600       # Establecer TTL

# Flush
FLUSHDB                 # Limpiar BD actual
FLUSHALL                # Limpiar todas (¡CUIDADO!)

# Monitor (debugging)
MONITOR                 # Ver comandos en tiempo real

# Salir
EXIT
```

---

## Comandos Git

### Flujo Básico

```bash
# Ver estado
git status

# Ver cambios
git diff
git diff --staged

# Agregar cambios
git add .
git add file.py

# Commit
git commit -m "feat: Add new feature"

# Push
git push origin branch-name

# Pull
git pull origin branch-name
```

### Branches

```bash
# Listar branches
git branch
git branch -a           # Incluir remotos

# Crear branch
git checkout -b feature/my-feature

# Cambiar branch
git checkout develop

# Merge
git checkout develop
git merge feature/my-feature

# Eliminar branch
git branch -d feature/my-feature
git push origin --delete feature/my-feature
```

### Logs

```bash
# Ver commits
git log
git log --oneline
git log --graph --oneline --all

# Ver cambios de commit
git show commit-hash

# Ver quien cambió qué
git blame file.py
```

### Stash

```bash
# Guardar cambios temporalmente
git stash

# Listar stashes
git stash list

# Aplicar stash
git stash apply
git stash pop           # Apply y eliminar

# Eliminar stash
git stash drop
git stash clear         # Eliminar todos
```

### Reset

```bash
# Deshacer cambios no staged
git checkout -- file.py

# Deshacer cambios staged
git reset HEAD file.py

# Reset a commit anterior (¡CUIDADO!)
git reset --soft HEAD~1 # Mantener cambios staged
git reset --hard HEAD~1 # Eliminar cambios
```

---

## Comandos Útiles Adicionales

### Docker

```bash
# Limpiar contenedores detenidos
docker container prune

# Limpiar imágenes no usadas
docker image prune

# Limpiar volúmenes no usados
docker volume prune

# Limpiar todo (¡CUIDADO!)
docker system prune -a --volumes

# Ver uso de espacio
docker system df
```

### Sistema

```bash
# Ver puertos en uso
netstat -tlnp | grep :8069

# Ver procesos
ps aux | grep odoo

# Ver uso de disco
df -h

# Ver uso de memoria
free -h

# Ver logs del sistema
journalctl -u docker

# Ver IP del contenedor
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' equilux_odoo
```

---

*Última actualización: 2025-10-27*
