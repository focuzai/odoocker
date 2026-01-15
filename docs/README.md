# Documentación Equilux.pe (Odoocker)

Bienvenido a la documentación completa del proyecto Equilux.pe, una solución ERP completa basada en Odoo 17.0 containerizado con Docker.

## Índice de Documentación

### 1. [Arquitectura General](./ARQUITECTURA.md)
Visión general de la arquitectura del proyecto, estructura de carpetas, componentes principales y tecnologías utilizadas.

### 2. [Servicios Docker](./SERVICIOS.md)
Documentación detallada de los 8 servicios Docker que componen el proyecto:
- Odoo
- PostgreSQL
- Nginx
- Nginx-Proxy
- Let's Encrypt
- Redis/KeyDB
- MinIO (S3)
- PgAdmin

### 3. [Addons y Módulos](./ADDONS.md)
Listado completo de los 378+ módulos instalados:
- Localización Peruana (Codlan Labs)
- OCA (Odoo Community Association)
- Focuzai y Ganemo
- Estructura y dependencias

### 4. [Configuración](./CONFIGURACION.md)
Variables de entorno, archivos de configuración y opciones disponibles:
- Variables .env
- odoo.conf
- nginx.conf
- redis/keydb.conf

### 5. [Deployment y Ambientes](./DEPLOYMENT.md)
Guía completa de deployment para diferentes ambientes:
- Fresh/Restore
- Local Development
- Debug
- Testing
- Staging
- Production

### 6. [Guía de Desarrollo](./DESARROLLO.md)
Información para desarrolladores:
- Setup de ambiente local
- Hot-reload y debugging
- Creación de addons personalizados
- Scripts útiles y comandos

### 7. [Scripts y Comandos](./SCRIPTS.md)
Documentación de todos los scripts disponibles y alias configurables.

## Información del Proyecto

- **Nombre:** Equilux.pe (Odoocker Framework)
- **Versión Odoo:** 17.0
- **Stack:** Docker, Odoo, PostgreSQL 16.4, Nginx, Redis/KeyDB
- **Tamaño Total:** 590 MB
- **Módulos:** 378+ addons instalados
- **Rama Actual:** 17.0
- **Rama Principal:** main

## Características Principales

- Solución containerizada completa para Odoo
- Localización completa para Perú (facturación electrónica SUNAT)
- Multi-ambiente (desarrollo, testing, staging, producción)
- SSL automático con Let's Encrypt
- Cache distribuido con Redis/KeyDB
- Storage S3-compatible con MinIO
- Debug remoto con VSCode
- Hot-reload para desarrollo
- 95+ módulos de localización peruana
- 144+ módulos OCA (Odoo Community Association)

## Enlaces Rápidos

- **Repositorio:** https://github.com/[usuario]/equilux.pe
- **Odoo Oficial:** https://www.odoo.com
- **Docker Hub:** https://hub.docker.com/_/odoo

## Soporte y Contribución

Para reportar issues o contribuir al proyecto, por favor consulte las guías de contribución en el repositorio principal.

---

*Última actualización: 2025-10-27*
