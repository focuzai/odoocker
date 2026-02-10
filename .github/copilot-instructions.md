# Odoocker: AI Agent Instructions

This is **Odoocker**, an Odoo 19 Docker framework for Community and Enterprise deployments. All behavior is environment-driven via `.env` configuration.

## Architecture Overview

**Container Stack:** odoo (v19 base image) → nginx (reverse proxy) → postgres → redis (KeyDB) → s3 (MinIO) → pgadmin

**Critical Pattern:** Configuration flows through `.env` → `odoorc.sh` (template substitution) → `odoo.conf` (INI format) → `entrypoint.sh` (dispatch logic). Never hardcode config; use environment variables.

## Development Environment Setup

**Initial Setup:**
```bash
cp .env.example .env
cp docker-compose.override.local.yml docker-compose.override.yml
echo '127.0.0.1 odoocker.test' | sudo tee -a /etc/hosts
```

**Essential Commands:**
- `docker-compose up -d --build && docker-compose logs -f odoo` - Start and monitor
- `docker-compose exec odoo bash` - Shell into Odoo container
- `docker-compose down && docker-compose pull && docker-compose build --no-cache && docker-compose up -d` - Full rebuild

## APP_ENV: The Master Controller

The `.env` variable `APP_ENV` dictates startup behavior in [entrypoint.sh](odoo/entrypoint.sh#L31):

| Mode | Behavior | Use Case |
|------|----------|----------|
| **local** | Respects INIT/UPDATE vars, hot reload via DEV_MODE | Development |
| **debug** | Runs debugpy on configured port for VSCode debugging | Debugging custom addons |
| **testing** | Creates test_${DB_NAME} database, installs ADDONS_TO_TEST, runs TEST_TAGS | Automated testing |
| **staging** | Sets UPDATE=all (upgrades everything), no workers | Pre-production verification |
| **fresh/restore** | Clears INIT/UPDATE, single worker, extended timeouts | Fresh installs or DB restoration |
| **production** | Uses WORKERS and WITHOUT_DEMO settings, no debug mode | Live deployment |

## Key Configuration Patterns

**Addon Loading:**
- `INIT`: Comma-separated list of addons to install (local, fresh, production)
- `UPDATE`: Addons to upgrade (overridden to `all` in staging mode)
- `LOAD`: Server-wide modules loaded before database connection (base,web,session_redis,attachment_s3 conditionally added)

**Feature Flags:**
- `USE_REDIS=true` → Automatically adds `session_redis` to LOAD
- `USE_S3=true` → Automatically adds `base_attachment_object_storage,attachment_s3` to LOAD
- `USE_SENTRY=true` → Automatically adds `sentry` to LOAD
- These are applied in both [odoorc.sh](odoo/odoorc.sh#L23) and [entrypoint.sh](odoo/entrypoint.sh#L13)

**Database Control:**
- `DBFILTER`: Regex for domain/subdomain isolation (default `.*` allows all)
- `DB_TEMPLATE`: Template for new database creation (default `unaccent_template`)
- `UNACCENT`: Whether to use unaccent extension (performance trade-off)

**Development Mode:**
- `DEV_MODE=reload,qweb` enables hot reload for Python + QWeb XML
- Incompatible with production/workers > 0; set WORKERS=0 for dev

## Custom Addon Structure

**Placement:**
- [odoo/custom-addons/](odoo/custom-addons/) - Your modules (mounted at runtime)
- [odoo/extra-addons/](odoo/extra-addons/) - Third-party modules
- Both directories auto-added to ADDONS_PATH in [odoo.conf](odoo/odoo.conf#L39)

**Module Template:**
```python
# __manifest__.py pattern
{
    'name': 'Module Display Name',
    'depends': ['base'],          # Never forget dependencies
    'data': ['views/module.xml'],
    'installable': True,
    'auto_install': False,        # Explicit unless enterprise blocking logic
}
```

**Pattern: Enterprise Blocking (Example)** - See [block_expire_date_fai](odoo/custom-addons/block_expire_date_fai/__manifest__.py#L8):
- Depends on `web_enterprise` to auto-install only on Enterprise
- Model inheritance pattern: `_inherit = 'ir.http'` → override `session_info()` for cross-request data

## Testing Strategy

**Run Tests:**
```bash
APP_ENV=testing ADDONS_TO_TEST=module1,module2 TEST_TAGS=tag docker-compose up
```

**Pattern:** Set TEST_TAGS to filter; avoid running all Odoo core tests. Uses `test_${DB_NAME}` database (fresh each run).

## Configuration Generation Deep Dive

1. **odoorc.sh** reads `.env` twice:
   - Pass 1: Export variables (handles nested references like `REDIS_URL=redis://odoo:${REDIS_PASSWORD}@...`)
   - Pass 2: Template substitution in [odoo.conf](odoo/odoo.conf) (sed replace `${VAR_NAME}` with exported values)

2. **entrypoint.sh** imports `.env` again and:
   - Conditionally adds modules to LOAD based on feature flags
   - Dispatches to different Odoo command based on APP_ENV

**Important:** Variable evaluation is bash-based, so special characters in passwords need escaping for sed (see odoorc.sh L49).

## Docker-Compose Profiles Pattern

Services use conditional startup via `profiles: [$NGINX_PROFILES]` etc. This allows selective service activation without manual file editing.

## Production Deployment Checklist

1. Backup via `/web/database/manager` UI
2. `git pull origin main` on host
3. Set `APP_ENV=staging` → `docker-compose up -d --build` (upgrades all modules)
4. Verify in staging environment
5. Set `APP_ENV=production` and `cp docker-compose.override.production.yml docker-compose.override.yml`
6. `docker-compose up -d` (production config active)

**⚠️ Never run `docker-compose down -v` in production** - destroys volumes (data loss).

## Common Modifications

**Add New Service:**
1. Define in [docker-compose.yml](docker-compose.yml)
2. Add profile variable to `.env.example` (e.g., `NEW_PROFILES=new-service`)
3. Reference `profiles: [$NEW_PROFILES]`

**Change Addon:** Edit INIT/UPDATE in `.env` → restart Odoo container. Config regeneration is automatic.

**Enable Redis Session Storage:** Set `USE_REDIS=true` in `.env` → LOAD automatically includes `session_redis`, and Redis environment vars are already in [docker-compose.yml](docker-compose.yml#L43-L54).

**Use External Addon Repository:**
- Add to `THIRD_PARTY_ADDONS` in `.env` (comma-separated GitHub URLs)
- Clone script runs in [odoo/Dockerfile](odoo/Dockerfile#L50+) during build
- URLs auto-added to ADDONS_PATH
