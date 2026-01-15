# Arquitectura del Proyecto

## Visión General

Equilux.pe es un framework completo para Odoo basado en Docker que proporciona una solución ERP enterprise-ready con localización completa para Perú.

### Características Principales

- **Framework Modular:** Soporta múltiples versiones de Odoo (13.0 - 19.0)
- **Containerizado:** Arquitectura basada en Docker Compose
- **Localizado:** 95+ módulos específicos para Perú
- **Enterprise-ready:** Pasarelas de pago, facturación electrónica, SMS
- **Multi-ambiente:** 7 ambientes configurables (fresh, local, debug, testing, full, staging, production)
- **Altamente Optimizado:** Límites de recursos, caché, compresión Brotli

## Stack Tecnológico

| Componente | Tecnología | Versión |
|------------|-----------|---------|
| **ERP Framework** | Odoo | 17.0 |
| **Base de Datos** | PostgreSQL | 16.4 |
| **Cache/Sessions** | KeyDB (Redis fork) | Latest |
| **Servidor Web** | Nginx + Brotli | 1.26.2 |
| **Proxy Reverso** | Nginx Proxy | 1.4.0 |
| **SSL/TLS** | ACME Companion | 2.2.9 |
| **Object Storage** | MinIO (S3) | Latest |
| **Admin BD** | PgAdmin | 8.11 |
| **Orquestación** | Docker Compose | - |

## Estructura de Carpetas

```
/opt/projects/equilux.pe/
├── .env                           # Variables de entorno principales
├── .env.example                   # Template de configuración
├── docker-compose.yml             # Configuración de servicios
├── docker-compose.override.yml    # Optimizaciones de recursos
├── setup-alias.sh                 # Configuración de alias bash
│
├── docs/                          # Documentación del proyecto
│   ├── README.md
│   ├── ARQUITECTURA.md
│   ├── SERVICIOS.md
│   ├── ADDONS.md
│   ├── CONFIGURACION.md
│   ├── DEPLOYMENT.md
│   └── DESARROLLO.md
│
├── odoo/                          # Configuración de Odoo
│   ├── Dockerfile                 # Imagen personalizada de Odoo
│   ├── odoo.conf                  # Configuración base
│   ├── requirements.txt           # Dependencias Python
│   ├── entrypoint.sh              # Punto de entrada del contenedor
│   ├── odoorc.sh                  # Generador de odoo.conf
│   ├── clone-addons.sh            # Clonador de addons
│   ├── third-party-addons.txt     # Lista de repos a clonar
│   ├── odoo-update.sh             # Actualizador de módulos
│   ├── custom-addons/             # Addons personalizados (vacío)
│   └── extra-addons/              # Addons de terceros (590 MB)
│       ├── codlan-labs/           # 95 módulos localización Perú
│       ├── focuzai/               # Módulos enterprise
│       ├── ganemo/                # Módulos específicos
│       └── OCA/                   # 144+ módulos OCA
│
├── postgres/                      # Configuración PostgreSQL
│   ├── Dockerfile
│   ├── entrypoint.sh              # Inicialización BD
│   └── psql.sh                    # Acceso rápido a psql
│
├── nginx/                         # Servidor web
│   ├── nginx.conf                 # Configuración principal
│   └── default.conf               # Configuración por defecto
│
├── nginx-proxy/                   # Proxy reverso
│   ├── nginx.conf
│   └── cors.conf                  # Configuración CORS
│
├── redis/                         # Cache distribuido
│   ├── Dockerfile
│   ├── keydb.conf
│   └── keydb.sh                   # Generador de config
│
├── pgadmin/                       # Admin de PostgreSQL
│
└── .vscode/                       # Configuración VSCode
    └── launch.json                # Debug configuration
```

## Diagrama de Arquitectura

```
                    ┌──────────────────┐
                    │   Internet       │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Nginx Proxy    │  (Puerto 80/443)
                    │  + Let's Encrypt│
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │     Nginx       │  (Compresión Brotli)
                    │  (Servidor Web) │
                    └────────┬────────┘
                             │
                   ┌─────────┴─────────┐
                   ▼                   ▼
          ┌────────────────┐   ┌──────────────┐
          │     Odoo       │◄──┤    Redis     │
          │   (ERP Core)   │   │  (Sessions)  │
          └────┬───────┬───┘   └──────────────┘
               │       │
       ┌───────┘       └───────┐
       ▼                       ▼
┌──────────────┐       ┌──────────────┐
│  PostgreSQL  │       │    MinIO     │
│  (Database)  │       │   (S3 Store) │
└──────────────┘       └──────────────┘
       │
       ▼
┌──────────────┐
│   PgAdmin    │
│  (Web Admin) │
└──────────────┘
```

## Flujo de Datos

### 1. Request HTTP/HTTPS
```
Usuario → Nginx Proxy → Nginx → Odoo → PostgreSQL
                                   ↓
                                Redis (Sessions)
                                   ↓
                                MinIO (Files)
```

### 2. WebSocket (Chat/Notificaciones)
```
Usuario → Nginx Proxy → Nginx (puerto 8072) → Odoo (Gevent)
```

### 3. Static Files
```
Usuario → Nginx → Cache (10 días) → /web/static/ (Odoo)
```

## Componentes Principales

### 1. **Odoo Core**
- **Puerto:** 8069 (HTTP), 8070 (Debug), 8071 (Shell), 8072 (WebSocket)
- **Recursos:** 3 CPU limit, 6GB RAM limit
- **Addons:** 378+ módulos instalados
- **Workers:** Configurable (CPU*2+1 recomendado)

### 2. **PostgreSQL**
- **Puerto:** 5432
- **Recursos:** 1 CPU, 2GB RAM
- **Extensiones:** UNACCENT, pg_trgm
- **Template:** unaccent_template
- **Configuración:** Optimizado para Odoo

### 3. **Nginx**
- **Compresión:** Brotli + Gzip
- **Cache:** 10 días para estáticos
- **Max Body Size:** 2GB
- **Timeouts:** Configurables

### 4. **Redis/KeyDB**
- **Puerto:** 6379
- **Threads:** 4
- **MaxMemory:** 384MB
- **Uso:** Sessions, cache distribuido

### 5. **MinIO (S3)**
- **Puerto:** 9000 (API), 9001 (Console)
- **Uso:** Almacenamiento de adjuntos
- **Compatible:** API S3 de AWS

## Volúmenes Persistentes

| Volumen | Ruta | Uso |
|---------|------|-----|
| `odoo-data` | /var/lib/odoo | Filestore de Odoo |
| `pg-data` | /var/lib/postgresql/data | Base de datos |
| `redis-data` | /data | Cache Redis |
| `s3-data` | /data | Storage MinIO |
| `pgadmin-data` | /var/lib/pgadmin | Config PgAdmin |
| `certs` | /etc/nginx/certs | Certificados SSL |
| `vhost` | /etc/nginx/vhost.d | Virtual hosts |
| `html` | /usr/share/nginx/html | Web root |
| `acme` | /etc/acme.sh | ACME challenge |

## Red Docker

- **Nombre:** internal
- **Tipo:** bridge
- **Subnet:** Auto-asignado por Docker
- **Comunicación:** Interna entre contenedores
- **Exposición:** Solo Nginx Proxy expone puertos 80/443

## Seguridad

### Características de Seguridad

1. **Red Interna:** Contenedores en red privada
2. **SSL/TLS:** Let's Encrypt automático en producción
3. **CORS:** Configuración personalizable
4. **Headers de Seguridad:** HSTS, X-Frame-Options
5. **Firewall:** Solo puertos 80/443 expuestos
6. **Secrets:** Variables de entorno para credenciales
7. **User Isolation:** Contenedores ejecutan como usuario no-root

### Mejores Prácticas Implementadas

- Límites de recursos por contenedor
- Healthchecks para servicios críticos
- Backups automáticos (configurable)
- Logs centralizados
- Actualización de seguridad automática (imágenes base)

## Escalabilidad

### Horizontal Scaling

El proyecto está preparado para escalado horizontal:

1. **Odoo Workers:** Aumentar WORKERS según CPU disponible
2. **Database Pooling:** DB_MAXCONN configurable
3. **Redis Cluster:** Migración a Redis Cluster para alta disponibilidad
4. **Load Balancer:** Nginx Proxy soporta múltiples backends

### Vertical Scaling

Recursos ajustables en `docker-compose.override.yml`:

```yaml
services:
  odoo:
    deploy:
      resources:
        limits:
          cpus: '6'      # Aumentar según necesidad
          memory: 12G    # Aumentar según necesidad
```

## Monitoreo

### Herramientas de Monitoreo

1. **Logs:** Docker logs con rotación
2. **Sentry:** Error tracking (configurable)
3. **PgAdmin:** Monitoreo de BD
4. **Nginx Logs:** Access/error logs con métricas

### Métricas Disponibles

- CPU/RAM por contenedor
- Conexiones activas PostgreSQL
- Cache hit rate Redis
- Response time Nginx
- Error rate Odoo

## Backup y Recuperación

### Estrategia de Backup

1. **Base de Datos:** `pg_dump` programado
2. **Filestore:** Backup de volumen `odoo-data`
3. **Configuración:** Versionado en Git
4. **S3 Storage:** Backup incremental MinIO

### Recuperación

```bash
# Modo restore
APP_ENV=fresh
# Restaurar dump de PostgreSQL
# Restaurar volumen odoo-data
```

## Integraciones

### Integraciones Activas

- **SUNAT:** Facturación electrónica UBL
- **Pasarelas de Pago:** Niubiz, MiCuenta Web
- **SMS:** AWS SNS
- **Email:** SMTP personalizado
- **Storage:** AWS S3, MinIO
- **Cloud:** Dropbox, NextCloud
- **Monitoring:** Sentry

### APIs Externas

- APIMigo (integración específica)
- PeruAPIs (consulta RUC/DNI)
- SUNAT WebServices (CPE)

## Performance

### Optimizaciones Implementadas

1. **Compresión:** Brotli + Gzip en Nginx
2. **Cache Estático:** 10 días para /web/static/
3. **Database Pooling:** 64 conexiones max
4. **Redis Sessions:** Sesiones en memoria
5. **Workers:** CPU*2+1 para concurrencia
6. **Resource Limits:** Prevención de memory leaks

### Tiempos de Respuesta Esperados

- **Homepage:** < 200ms
- **List View:** < 500ms
- **Form View:** < 300ms
- **Search:** < 1s
- **Report Generation:** < 3s

---

*Última actualización: 2025-10-27*
