# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is **Odoocker**, an Odoo Docker framework for both Community and Enterprise editions (v19). It's a comprehensive Docker-based development and deployment solution that goes beyond the official Odoo Docker setup.

## Architecture

### Container Structure
- **odoo**: Main Odoo application server with custom entrypoint logic
- **postgres**: PostgreSQL database with custom initialization
- **nginx**: Reverse proxy with Brotli compression  
- **nginx-proxy**: Nginx proxy manager with virtual host support
- **letsencrypt**: Automatic SSL certificate management
- **redis**: KeyDB (Redis-compatible) for session storage
- **s3**: MinIO S3-compatible object storage
- **pgadmin**: Database administration interface

### Key Directories
- `odoo/`: Odoo application files, Dockerfile, entrypoint scripts
  - `custom-addons/`: Local custom modules
  - `extra-addons/`: Third-party modules
- `nginx/` & `nginx-proxy/`: Web server configurations
- `postgres/`: Database initialization and configuration
- `redis/`: Redis/KeyDB configuration

## Development Commands

### Environment Setup
```bash
# Clone and setup
cp .env.example .env
cp docker-compose.override.local.yml docker-compose.override.yml

# Add to hosts file (Unix)
echo '127.0.0.1 erp.odoocker.test' | sudo tee -a /etc/hosts
echo '127.0.0.1 pgladmin.odoocker.test' | sudo tee -a /etc/hosts
```

### Docker Operations
```bash
# Start all services
docker-compose up -d --build && docker-compose logs odoo

# Restart with fresh build
docker-compose down && docker-compose up -d --build && docker-compose logs odoo

# View logs
docker-compose logs -f --tail 2000 odoo

# Hard deployment (pulls latest everything)
docker-compose down && docker-compose pull && docker-compose build --no-cache && docker-compose up -d && docker-compose logs -f odoo
```

### Odoo Operations
```bash
# Shell access
docker-compose exec odoo bash

# Odoo shell
docker-compose exec odoo bash
# Then: odoo shell --http-port=8071

# Scaffold new addon
docker-compose exec -u root odoo bash
# cd /usr/lib/python3/dist-packages/odoo/custom-addons
# odoo scaffold <addon_name>
```

## Environment Configuration

The `.env` file controls all aspects of the deployment through the `APP_ENV` variable:

### APP_ENV Options
- **fresh/restore**: For fresh installations or database restoration
- **local**: Standard development with .env variables, supports hot reload with `DEV_MODE=reload,qweb`
- **debug**: Local mode + Python debugger support (debugpy on port configured in .env)
- **testing**: Automated testing with fresh test database (`test_${DB_NAME}`)
- **staging**: Updates all modules (`UPDATE=all`), ideal for deployments
- **production**: Production-ready with SSL certificates via Let's Encrypt

### Key Configuration Variables
```bash
APP_ENV=local                    # Environment mode
INIT=module1,module2            # Modules to install
UPDATE=module1,module2          # Modules to update  
LOAD=base,web                   # Server-wide modules
DEV_MODE=reload,qweb           # Development features
WORKERS=0                       # Worker processes (0 for dev)
TEST_TAGS=tag1                  # Test filtering
ADDONS_TO_TEST=addon1          # Modules to test
```

## Configuration Generation

- `odoorc.sh`: Generates `odoo.conf` from `.env` variables using template substitution
- `entrypoint.sh`: Handles different startup modes based on `APP_ENV`
- All configuration is environment-driven through `.env` file

## Testing

Set `APP_ENV=testing` and configure:
- `ADDONS_TO_TEST`: Comma-separated list of addons to install and test
- `TEST_TAGS`: Filter tests by tags (recommended to avoid running all Odoo tests)

## Production Deployment Process

1. Backup databases from `/web/database/manager`
2. Update system: `sudo apt update && sudo apt upgrade -y`
3. Reboot if needed: `sudo reboot`
4. Pull latest code: `git pull origin main`
5. Set `APP_ENV=staging` and run upgrade
6. Set `APP_ENV=production` and deploy
7. Replace override file: `cp docker-compose.override.production.yml docker-compose.override.yml`

## Integration Features

- **Redis Sessions**: Set `USE_REDIS=true` to enable session storage in Redis
- **S3 Storage**: Set `USE_S3=true` for object storage (file attachments)
- **Sentry**: Set `USE_SENTRY=true` for error tracking
- **Enterprise**: Configure `GITHUB_USER` and `GITHUB_ACCESS_TOKEN` for Enterprise modules

## Important Notes

- **Never run `docker-compose down -v` in production** - destroys all data and certificates
- Use `TEST_TAGS` when testing to avoid running all Odoo core tests
- The framework uses profiles to conditionally start services based on SERVICES variable
- All addon paths are automatically configured: community, enterprise, extra-addons, custom-addons