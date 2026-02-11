# Odoocker: The Ultimate Odoo Docker Framework

Welcome to Odoocker, a game-changer in the world of Odoo Development and Deployment. This tool is meticulously crafted to revolutionize your experience with Odoo, ensuring simplicity, efficiency, and a top-tier development journey. And while it’s rooted in the principles of the Official Odoo Docker setup, it goes several steps beyond.

Whether you're using the **Community** or **Enterprise** edition, this **Docker** solution is tailored just for you.

**Best part of this?** You don't need any prior knowledge of **Docker**, **Odoo** or any technology that involves this Framework. We stick to Docker philosophy: **Use it, then learn about it.**

Feel free to post a Pull Request to continue enhancing this project.

### Why Odoocker Stands Out:
1. 🌐 **Universal:** Suitable for both Odoo Community and Enterprise editions.
2. 📦 **Easy Setup:** Clone, configure `.env` file, and you're ready to deploy.
3. 🔒 **Secure:** Automatic SSL certificate renewal to keep your data safe (for production only).

In essence, Odoocker isn't just another tool, it's a philosophy. So, whether you’re a seasoned Odoo veteran or just starting your journey, Odoocker is here to make your journey easier.

## Contents

- [Odoocker: The Ultimate Odoo Docker Framework](#odoocker-the-ultimate-odoo-docker-framework)
    - [Why Odoocker Stands Out:](#why-odoocker-stands-out)
  - [Contents](#contents)
- [Deployment Modes](#deployment-modes)
  - [Quick Start: Standalone (All-in-One)](#quick-start-standalone-all-in-one)
  - [Quick Start: Main Infrastructure](#quick-start-main-infrastructure)
  - [Quick Start: Multi-Tenant Instance](#quick-start-multi-tenant-instance)
  - [Quick Start: Enterprise Instance](#quick-start-enterprise-instance)
- [Configuration Templates](#configuration-templates)
- [The `.env` File](#the-env-file)
  - [Environment-based actions:](#environment-based-actions)
    - [1. Fresh or Restore](#1-fresh-or-restore)
    - [2. Local:](#2-local)
    - [3. Debug:](#3-debug)
    - [4. Testing:](#4-testing)
    - [5. Full:](#5-full)
    - [6. Staging:](#6-staging)
    - [7. Production:](#7-production)
- [Pro(d) Tips](#prod-tips)
  - [1. Search through all Addons at once:](#1-search-through-all-addons-at-once)
  - [2. Define the following aliases:](#2-define-the-following-aliases)
  - [3. NEVER run `docker-compose down -v` in Production](#3-never-run-docker-compose-down--v-in-production)
  - [4. Odoo Shell](#4-odoo-shell)
  - [5. Odoo Scaffold](#5-odoo-scaffold)
  - [6. Colorize your branches](#6-colorize-your-branches)
- [DB Connection](#db-connection)
  - [PgAdmin](#pgadmin)
- [Deployment Process](#deployment-process)
- [Multi-Instance Architecture](#multi-instance-architecture)
  - [Multi-Tenant Architecture](#multi-tenant-architecture)
  - [Enterprise Architecture](#enterprise-architecture)
  - [Port Allocation](#port-allocation)
  - [Auto-Provisioning](#auto-provisioning)
- [Footnote](#footnote)

# Deployment Modes

Odoocker supports 3 deployment modes, each with its own `.env` template and compose file:

| Mode | Compose File | `.env` Template | Use Case |
|------|-------------|-----------------|----------|
| **Standalone** | `docker-compose.all.yml` | `.env.example` | Single instance with all services (dev/demo) |
| **Main + Multi-Tenant** | `docker-compose.main.yml` + `docker-compose.instance.yml` | `.env.main.example` + `.env.multi-tenant.example` | Shared postgres, multiple Odoo instances |
| **Enterprise** | `docker-compose.enterprise.yml` | `.env.enterprise.example` | Standalone instance with its own postgres |

## Quick Start: Standalone (All-in-One)

For development or single-client deployments with all services in one stack:

```bash
git clone -b 19.0 git@github.com:focuz-ai/odoocker.git o19_docker
cd o19_docker
cp .env.example .env
cp docker-compose.all.yml docker-compose.yml
cp docker-compose.override.local.yml docker-compose.override.yml

# Edit .env: set CLIENT, GITHUB_USER, GITHUB_ACCESS_TOKEN
echo '127.0.0.1 odoocker.test' | sudo tee -a /etc/hosts

docker compose up -d --build && docker compose logs -f odoo
```

Access: http://localhost:8069/web/login

## Quick Start: Main Infrastructure

Deploy shared postgres + nginx-proxy + SSL for multi-tenant environments:

```bash
cd o19_docker
cp .env.main.example .env

# Edit .env:
#   - DB_USER_1=cliente_1, DB_PASSWORD_1=odoo123456
#   - DB_USER_2=cliente_2, DB_PASSWORD_2=odoo123456
#   - Add more DB_USER_N as needed

docker compose -f docker-compose.main.yml -p o19_main up -d --build
```

This creates: PostgreSQL 17 + pgvector, nginx-proxy (ports 80/443), letsencrypt, `unaccent_template` database with extensions (unaccent, vector, pg_trgm).

Verify:
```bash
docker exec postgres psql -U postgres -c "\du"
docker exec postgres psql -U postgres -d unaccent_template -c "\dx"
```

## Quick Start: Multi-Tenant Instance

Deploy a client instance that connects to the shared postgres from Main:

```bash
git clone -b 19.0 git@github.com:focuz-ai/odoocker.git o19_cliente_1
cd o19_cliente_1
cp .env.multi-tenant.example .env
cp docker-compose.instance.yml docker-compose.yml
cp docker-compose.override.instance.local.yml docker-compose.override.yml

# Edit .env:
#   CLIENT=cliente_1
#   DB_USER=cliente_1, DB_PASSWORD=odoo123456
#   GITHUB_USER=..., GITHUB_ACCESS_TOKEN=...

# Edit docker-compose.override.yml: set unique ports (8069:80, 8070:8070, etc.)

echo '127.0.0.1 cliente1.test' | sudo tee -a /etc/hosts
docker compose up -d --build && docker compose logs -f odoo
```

Access: http://localhost:8069/web/login

## Quick Start: Enterprise Instance

Deploy a standalone instance with its **own postgres** (independent of shared infra):

```bash
git clone -b 19.0 git@github.com:focuz-ai/odoocker.git o19_cliente_4
cd o19_cliente_4
cp .env.enterprise.example .env
cp docker-compose.enterprise.yml docker-compose.yml
cp docker-compose.override.enterprise.local.yml docker-compose.override.yml

# Edit .env:
#   CLIENT=cliente_4
#   DB_USER=odoo, DB_PASSWORD=odoo123456
#   GITHUB_USER=..., GITHUB_ACCESS_TOKEN=...

# Edit docker-compose.override.yml: set unique ports
#   Odoo: 8369:80, 8370:8070, 8371:8071, 8372:8072
#   Postgres: 5437:5432

echo '127.0.0.1 cliente4.test' | sudo tee -a /etc/hosts
docker compose up -d --build && docker compose logs -f odoo
```

Access: http://localhost:8369/web/login

Verify standalone postgres:
```bash
docker compose exec postgres psql -U postgres -c "\du"    # odoo user (CREATEDB, no SUPERUSER)
docker compose exec postgres psql -U postgres -c "\l"     # Only this client's databases
docker compose exec postgres psql -U postgres -d cliente4.test -c "\dx"  # unaccent, vector, pg_trgm
```

# Configuration Templates

| File | Lines | Purpose |
|------|-------|---------|
| `.env.example` | ~434 | Full monolithic config (all services, all modes) |
| `.env.main.example` | ~99 | Main infra only: postgres + proxy + acme |
| `.env.multi-tenant.example` | ~352 | Tenant instance: odoo + nginx, shared postgres |
| `.env.enterprise.example` | ~442 | Standalone: odoo + nginx + own postgres + pgadmin |

| Compose File | Services |
|-------------|----------|
| `docker-compose.all.yml` | All services in one stack |
| `docker-compose.main.yml` | postgres, nginx-proxy, letsencrypt |
| `docker-compose.instance.yml` | odoo, nginx (connects to external postgres via `db` network) |
| `docker-compose.enterprise.yml` | odoo, nginx, postgres (project-isolated `default` network + external `internal`) |

| Override | Purpose |
|----------|---------|
| `docker-compose.override.local.yml` | Dev: direct ports, `restart: 'no'` |
| `docker-compose.override.production.yml` | Prod: localhost-bound ports, `restart: unless-stopped` |
| `docker-compose.override.enterprise.local.yml` | Enterprise dev: ports 8069:80, pg 5437:5432 |
| `docker-compose.override.enterprise.production.yml` | Enterprise prod: localhost-bound, `restart: unless-stopped` |

# The `.env` File
The environment variables located in [`.env`](https://github.com/odoocker/odoocker/blob/main/.env.example) provide dynamic configurations to Odoo and the project in general.
The [`odoo.conf`](https://github.com/odoocker/odoocker/blob/main/odoo/odoo.example.conf) file is generated by the [`odoorc.sh`](https://github.com/odoocker/odoocker/blob/main/odoo/odoorc.sh) script based on the environment variables.
<br>
This file is divided in sections, you most likely are going to focus on the `Main Configuration` section. This provides quick access to project and `odoo.conf` variables. The rest of section are container specific variables for different container. (Note: you may find *repeated variables* like `SUPPORT_EMAIL=${SUPPORT_EMAIL}` which interacts with different containers. This is to explicitly denote in the `.env` file that this variable is being shared through those containers.

Sample `.env` file:
```
# Odoo
APP_ENV=debug
INIT=
UPDATE=my_custom_addon
LOAD=base,web
WORKERS=2
DEV_MODE=reload,qweb
DOMAIN1=odoocker.test
DOMAIN2=www.odoocker.test
DOMAIN3=erp.odoocker.test
DOMAIN=${DOMAIN1},${DOMAIN2},${DOMAIN3}

# Enterprise (GitHub User with access to Odoo Enterprise [https://github.com/odoo/enterprise] Repo)
# If not present, Odoo Community will be brought up.
GITHUB_USER=odoocker
GITHUB_ACCESS_TOKEN=ghp_token

# Database
ADMIN_PASSWD=odoo
DB_HOST=postgres (container or external host)
DB_PORT=5432
DB_NAME=my-odoo-db
DB_USER=odoo
DB_PASSWORD=odoo
LOAD_LANGUAGE=es_MX
...
```
<br>

## Environment-based actions:
[`odoo/entrypoint.sh`](https://github.com/odoocker/odoocker/blob/main/odoo/entrypoint.sh) file is the gateway for our Odoo container. Depending on the `APP_ENV` and the rest of the environment variables, it determines how to start the Odoo service (like local, testing, production, etc.) with different configurations.
<br>
In all environments, `odoo.conf` follows the `.env` file variables. Some environments may have command-line parameter to overwrite certain configurations.

**To bring up all the environments run**:
```
docker-compose up -d --build && docker-compose logs odoo
```
Restart adding `down`:
```
docker-compose down && docker-compose up -d --build && docker-compose logs -f odoo
```

### 1. Fresh or Restore
These environments (`APP_ENV=fresh` or `APP_ENV=restore`) will have no database created. Are perfect for setting up a **fresh database** instance or **restoring a production database**.

### 2. Local:
This environment (`APP_ENV=local`) will strictly follow the `.env` variables with no command-line overwrites. You'll most likely be using this regularly.
Use `DEV_MODE=reload,qweb` to activate hot reload when changing `python` and `xml` files.
<br>
If you prefer to update the packages everytime you restart Odoo container, you can set `UPDATE=module1,module2,module3`.

### 3. Debug:
This environment (`APP_ENV=debug`) works same way as local, but it starts Odoo using the `debugpy` library. Thanks to our [`.vscode/launch.json`](https://github.com/odoocker/odoocker/blob/main/.vscode/launch.json), if you are using **Visual Studio Code**, you can start a Debugger session so the container is aware of your breakpoints and stop wherever you need. This is **my favorite** environment to work since I use the debugger a lot while developing.

### 4. Testing:
This environment (`APP_ENV=testing`) is specific for running tests *(and will be included in a CI/CD pipeline in a future version)*. It help us test the modules we are developing to ensure a safe deployment.
<br>
A `test_DB_NAME` database is automagically created.
The `ADDONS_TO_TEST=addon_1` are installed in that fresh DB.
Use `TEST_TAGS=test_tag_1` to filter your tests.

**NOTE: Avoid running tests without tags**; otherwise, it will trigger tests in all installed addons and we don't want this. For now, let's assume Odoo Community & Enterprise tests passed and only focus on the things you need to test.

### 5. Full:
This environment (`APP_ENV=full`) will install the `INIT` modules in a new or existing `DB_NAME`. It allows us to have a fresh production database replica.

### 6. Staging:
This environment (`APP_ENV=staging`) sets `UPDATE=all`; it allows us to **update all installed addons at once**.
<br>
It also allows to install new packages before the upgrade through `INIT`.
<br>
It's highly recommended to use this command to run this environment
```
docker-compose down && docker-compose pull && docker-compose build --no-cache && docker-compose up -d && docker-compose logs -f odoo
```

This will `pull` the latest *Odoo Community, Enterprise, Extra and Custom addons*, basically, it **upgrades the whole Odoo instance** to the newest. Additionally, it will also pull the latest images of the other containers in this project. This environment is perfect for deployments.

**NOTE: Do not bring down & up again, unless you want to perform a whole upgrade again.**

### 7. Production:
This environment (`APP_ENV=production`) ensures no demo data is loaded, debugging and dev_mode are turned off. It also brings up the `Let's Encrypt` container, so you won't worry about `SSL Certificates` anymore! Some `.env` variables are overwritten in this setup.

- Take down previous setup of containers
```
docker-compose down
```
- Replace the `docker-compose.override.yml` with `docker-compose.override.production.yml` to bring `Let's Encrypt` container.
```
cp docker-compose.override.production.yml docker-compose.override.yml
```
- Update .env `SERVICES` (add `acme`) and `ACME_CA_URI` (use production link).
- Make sure the DNS record of your `DOMAIN` is pointing to your server.
- Rebuild the containers
```
docker-compose up -d --build && docker-compose logs odoo
```

# Pro(d) Tips
The following tips will enhance your developing and production experience.

## 1. Search through all Addons at once:
If you are using `Visual Studio Code` & the **Docker Extension** is installed, you can open the Odoo Container in the `ROOT_PATH`. There you will find all Odoo `Community Addons`, `Enterprise Addons`, `Extra Addons` and `Custom Addons` in the same folder level.
<br>
Using the Search Panel will allow you to look at every single reference of what you are looking for in the whole Odoo Instance and not just in your addons.

## 2. Define the following aliases:
```
alias odoo='cd odoocker'

alias hard-deploy='docker-compose down && git pull && docker-compose pull && docker-compose build --no-cache && docker-compose up -d && docker-compose logs -f odoo'

alias deploy='docker-compose down && git pull && docker-compose up -d --build && docker-compose logs -f --tail 2000 odoo'

alias logs='docker-compose logs -f --tail 2000 odoo'
```

## 3. NEVER run `docker-compose down -v` in Production
...without having a `tested backed up` database
<br>
Have in mind that dropping volumes will destroy DB data, Odoo Conf & Filestore, *Let's Encrypt certificates, and more!* If you execute this command several times in `prod` in a short period of time, you may reach the `Let's Encrypt certificates limit`` and Odoocker won't be able to generate new ones after **several hours**.

## 4. Odoo Shell
1. Log into the odoo container
```
docker-compose exec odoo bash
```
2. Start Odoo shell running:
```
odoo shell --http-port=8071
```

## 5. Odoo Scaffold
1. Log into the odoo container
```
docker-compose exec -u root odoo
```
2. Navigate to custom addons folder inside the container
```
cd /usr/lib/python3/dist-packages/odoo/custom-addons
```
3. Create new addons running:
```
odoo scaffold <addon_name>
```
- The new addon will be available in the `odoo/custom_addons` folder in this project.

## 6. Colorize your branches
Add the following to `~/.bashrc`
```
# Color git branches
function parse_git_branch () {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

if [ "$color_prompt" = yes ]; then
    #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    # Color git branches
    PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w \[\033[01;31m\]\$(parse_git_branch)\[\033[00m\]\$ "
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt
```

# DB Connection
- Any other Postgres Database Manager can connect to the DB using the `.env` credentials.

## PgAdmin
- This project comes with a PgAdmin container which is loaded only in `docker-compose.override.pgadmin.yml`.
In order to manage DB we provide a pgAdmin container.
In order to bring this up, simply run:
```
docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.pgadmin.yml up -d --build
```
And to turn down
```
docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.pgadmin.yml down
```

If your instance has pgAdmin, make sure you adapt your aliases to this configuration.

# Deployment Process
Note: the deployment process is easier & faster with aliases.

1. Backup the production Databases from `/web/database/manager`.
2. Run
```
sudo apt update && sudo apt upgrade -y
```
- If packages are kept, install them
```
sudo apt install <kept packages>
```
3. Restart the server
```
sudo reboot
```
- Make sure there are no more upgrades or possible kept packages
```
sudo apt update && sudo apt upgrade -y
```
4. Go to the project folder in /home/ubuntu or (~)
```
cd ~/odoocker
```
or with alias:
```
odoo
```
5. Pull the latest `main` branch changes.
```
git pull origin main
```
6. Set [`Staging`](#6-staging) environment
7. Set [`Production`](#7-production) environment

# Multi-Instance Architecture

Odoocker supports two multi-instance strategies: **Multi-Tenant** (shared postgres) and **Enterprise** (own postgres).

## Multi-Tenant Architecture

Multiple Odoo instances share a single PostgreSQL server. Each client gets its own database user with `CREATEDB` (no SUPERUSER), CONNECT isolation, and auto-provisioned databases from `unaccent_template`.

```
docker-compose.main.yml (shared infrastructure)
├── postgres (PostgreSQL 17 + pgvector 0.8.1, port 5436)
├── nginx-proxy (ports 80/443)
└── letsencrypt (auto SSL)

o19_cliente_1/ (multi-tenant)        o19_cliente_2/ (multi-tenant)
├── odoo (port 8069)                 ├── odoo (port 8169)
├── nginx                            ├── nginx
└── connects to shared postgres      └── connects to shared postgres
    via db + internal networks           via db + internal networks
    with user: cliente_1                 with user: cliente_2
```

User provisioning in `docker-compose.main.yml` via `DB_USER_N`/`DB_PASSWORD_N` pairs in `.env`.
Odoo entrypoint auto-creates the user if it doesn't exist and pre-creates the database with CONNECT isolation.

## Enterprise Architecture

Each instance runs its own PostgreSQL, completely isolated from other instances. Ideal for clients that need full database control or cannot share infrastructure.

```
o19_cliente_4/ (enterprise - standalone)
├── postgres (own, port 5437)    <- project-isolated network
├── odoo (port 8369)
├── nginx
└── pgadmin (optional)

Networks:
  default  -> odoo <-> postgres <-> nginx (project-isolated)
  internal -> nginx <-> nginx-proxy (shared, for production SSL)
```

The enterprise compose uses project-scoped `default` network (no cross-project DNS leakage) and connects nginx to the external `internal` network for nginx-proxy discovery in production.

## Port Allocation

Each client instance needs unique host ports. Convention:

| Client | HTTP | Debug | XMLRPC | Longpolling | Postgres |
|--------|------|-------|--------|-------------|----------|
| cliente_1 | 8069 | 8070 | 8071 | 8072 | shared (5436) |
| cliente_2 | 8169 | 8170 | 8171 | 8172 | shared (5436) |
| cliente_3 | 8269 | 8270 | 8271 | 8272 | shared (5436) |
| cliente_4 (enterprise) | 8369 | 8370 | 8371 | 8372 | 5437 (own) |
| cliente_N | 8069+(N-1)*100 | ... | ... | ... | 5437+ (if enterprise) |

For production, nginx-proxy routes by domain name; host port mapping is only for development.

## Auto-Provisioning

The `odoo/entrypoint.sh` automatically handles user and database provisioning when `POSTGRES_MAIN_USER` and `POSTGRES_MAIN_PASSWORD` are set:

1. Waits for PostgreSQL to be available (max 30s)
2. Creates `DB_USER` with `CREATEDB` (no SUPERUSER) if it doesn't exist
3. Grants `CONNECT` on `DB_TEMPLATE` to the user
4. Pre-creates `DB_NAME` from `DB_TEMPLATE` if it doesn't exist
5. Enforces CONNECT isolation: revokes PUBLIC access, grants only to owner

This works for both multi-tenant (connecting to shared postgres) and enterprise (connecting to local postgres) modes.

# Footnote
This project is based on the [Official Odoo Docker](https://hub.docker.com/_/odoo/) image. We've strived to ensure a seamless integration with the original Docker setup while making necessary customizations to suit our requirements. We encourage contributors and users to frequently refer to the official documentation for foundational concepts and updates. Thank you for your continued support and trust in our project.
