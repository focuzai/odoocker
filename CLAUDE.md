# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**Odoocker** is a Docker-based Odoo v19 development and deployment framework supporting both Community and Enterprise editions. It provides environment-driven configuration where all behavior flows through `.env` variables.

## Architecture

### Configuration Flow
`.env` → `odoorc.sh` (template substitution) → `odoo.conf` → `entrypoint.sh` (APP_ENV dispatch)

### Container Stack
- **odoo**: Main application (base image `odoo:19.0`)
- **nginx**: Reverse proxy with Brotli compression
- **nginx-proxy**: Virtual host support for multi-domain
- **letsencrypt**: Automatic SSL certificates
- **postgres**: PostgreSQL with custom initialization
- **redis**: KeyDB for session storage
- **s3**: MinIO object storage
- **pgadmin**: Database admin interface

### Addon Paths (auto-configured in ADDONS_PATH)
- `odoo/custom-addons/` - Your modules (mounted at runtime)
- `odoo/extra-addons/` - Third-party modules (mounted at runtime)
- Enterprise and third-party addons cloned during build via `clone-addons.sh`

## Development Commands

### Initial Setup
```bash
cp .env.example .env
cp docker-compose.all.yml docker-compose.yml
cp docker-compose.override.local.yml docker-compose.override.yml

# Add to /etc/hosts
echo '127.0.0.1 odoocker.test pgadmin.odoocker.test s3.odoocker.test' | sudo tee -a /etc/hosts
```

### Multi-Instance Setup (optional)
```bash
cp docker-compose.instance.yml docker-compose.yml
cp docker-compose.override.instance.local.yml docker-compose.override.yml
```

### Docker Operations
```bash
# Start services
docker-compose up -d --build && docker-compose logs -f odoo

# Restart with rebuild
docker-compose down && docker-compose up -d --build && docker-compose logs -f odoo

# Full rebuild (pulls latest images)
docker-compose down && docker-compose pull && docker-compose build --no-cache && docker-compose up -d && docker-compose logs -f odoo

# View logs
docker-compose logs -f --tail 2000 odoo

# Shell into container
docker-compose exec odoo bash

# Odoo shell (inside container)
odoo shell --http-port=8071

# Scaffold new addon (as root)
docker-compose exec -u root odoo bash
cd /usr/lib/python3/dist-packages/odoo/custom-addons
odoo scaffold <addon_name>
```

## APP_ENV Modes

The `APP_ENV` variable in `.env` controls startup behavior in `entrypoint.sh`:

| Mode | Behavior |
|------|----------|
| `local` | Standard development, respects INIT/UPDATE/DEV_MODE from .env |
| `debug` | Runs debugpy for VSCode debugging on DEBUG_PORT (default 8070) |
| `testing` | Creates `test_${DB_NAME}`, installs ADDONS_TO_TEST, runs TEST_TAGS |
| `staging` | Forces UPDATE=all, no workers, extended timeouts |
| `fresh`/`restore` | No database selected, for fresh installs or DB restoration |
| `production` | Production config, no dev mode, workers enabled |

## Key Configuration Variables

```bash
# Core
APP_ENV=local                    # Environment mode
INIT=module1,module2            # Modules to install
UPDATE=module1,module2          # Modules to update
LOAD=base,web                   # Server-wide modules
DEV_MODE=reload,qweb            # Hot reload for Python and QWeb
WORKERS=0                       # 0 for development (required for DEV_MODE)

# Feature Flags (auto-add modules to LOAD)
USE_REDIS=true                  # Adds session_redis
USE_S3=true                     # Adds base_attachment_object_storage,attachment_s3
USE_SENTRY=true                 # Adds sentry

# Testing
ADDONS_TO_TEST=addon1,addon2    # Modules to install in test DB
TEST_TAGS=tag1                  # Filter tests (use to avoid running all Odoo tests)

# Enterprise (optional)
GITHUB_USER=username
GITHUB_ACCESS_TOKEN=ghp_token
```

## Third-Party Addons

Configure in `odoo/third-party-addons.txt` (read by `clone-addons.sh` during build):

```bash
# Format: <public|private|enterprise> <repo_url> <module1> <condition1> ...

# Clone enterprise (if credentials provided)
enterprise https://github.com/odoo/enterprise true

# Conditional module cloning
public https://github.com/org/repo.git session_redis ${USE_REDIS} attachment_s3 ${USE_S3}
private https://github.com/org/private.git module_name true
```

## Debugging with VSCode

1. Set `APP_ENV=debug` in `.env`
2. Start containers: `docker-compose up -d --build`
3. In VSCode, use "Odoocker Debugger" launch configuration (port 8070)
4. Set breakpoints in `odoo/custom-addons/` or `odoo/extra-addons/`

## Production Deployment

1. Backup databases from `/web/database/manager`
2. `git pull origin main`
3. Set `APP_ENV=staging` and run: `docker-compose down && docker-compose pull && docker-compose build --no-cache && docker-compose up -d`
4. Verify, then set `APP_ENV=production`
5. `cp docker-compose.override.production.yml docker-compose.override.yml`
6. Update ACME_CA_URI in .env to production Let's Encrypt endpoint
7. `docker-compose up -d`

**Warning**: Never run `docker-compose down -v` in production - destroys all volumes including SSL certificates.

## Profiles System

Services are conditionally started via `COMPOSE_PROFILES` (set from `SERVICES` variable). Each service has a profile variable (e.g., `ODOO_PROFILES=odoo`, `POSTGRES_PROFILES=postgres`). Set `SERVICES=odoo,nginx,proxy,postgres` to control which containers start.
