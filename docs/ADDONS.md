# Addons y Módulos

Este documento detalla los 378+ módulos instalados en el proyecto Equilux.pe, organizados por origen y funcionalidad.

## Resumen General

| Origen | Tamaño | Módulos Aprox. | Descripción |
|--------|--------|----------------|-------------|
| **Codlan Labs** | 50 MB | 95 | Localización Peruana |
| **OCA** | 341 MB | 144+ | Odoo Community Association |
| **Focuzai** | 117 MB | N/A | Enterprise Extensions |
| **Ganemo** | 81 MB | N/A | Custom Modules |
| **TOTAL** | 589 MB | 378+ | Todos los addons |

---

## 1. Codlan Labs (Localización Peruana)

### 1.1. l10n_pe_base (32 módulos)

Módulos base para localización peruana, incluyendo facturación electrónica SUNAT.

#### Facturación Electrónica

| Módulo | Descripción |
|--------|-------------|
| `l10n_pe_edi_doc` | Documentos electrónicos SUNAT (facturas, boletas, notas) |
| `l10n_pe_consulta_cpe` | Consulta de CPE en SUNAT |
| `l10n_pe_edi_nubefact` | Integración con NubeFact (OSE) |
| `l10n_pe_edi_odoofact` | Integración con OdooFact |
| `l10n_pe_invoice_nc` | Notas de crédito y débito |
| `l10n_pe_invoice_ubl` | Generación de XML UBL 2.1 |

#### Partners y Contactos

| Módulo | Descripción |
|--------|-------------|
| `l10n_pe_partner` | Gestión de partners peruanos (RUC, DNI) |
| `bo_pe_partner` | Partners con validación SUNAT |
| `bo_pe_partner_type` | Tipos de documento de identidad |
| `l10n_pe_partner_search` | Búsqueda de RUC/DNI en SUNAT |

#### Point of Sale (POS)

| Módulo | Descripción |
|--------|-------------|
| `l10n_pe_pos` | POS adaptado para Perú |
| `l10n_pe_pos_edi` | POS con facturación electrónica |
| `l10n_pe_pos_voucher` | Vouchers de POS |
| `l10n_pe_pos_receipt` | Tickets de POS personalizados |

#### Pagos y Pasarelas

| Módulo | Descripción |
|--------|-------------|
| `payment_niubiz` | Pasarela de pago Niubiz (Visa/MasterCard) |
| `payment_micuentaweb` | Pasarela MiCuenta Web |
| `payment_culqi` | Pasarela Culqi |
| `payment_mercadopago` | MercadoPago Perú |

#### Logística y Delivery

| Módulo | Descripción |
|--------|-------------|
| `l10n_pe_delivery_carrier` | Transportistas peruanos |
| `l10n_pe_stock` | Gestión de stock para Perú |
| `l10n_pe_delivery_guide` | Guía de remisión electrónica |

#### Comunicación y Notificaciones

| Módulo | Descripción |
|--------|-------------|
| `sms_aws_sns` | Envío de SMS via AWS SNS |
| `aws_base` | Configuración base AWS |
| `whatsapp_connector` | Integración WhatsApp Business |

#### Reportes y Diseño

| Módulo | Descripción |
|--------|-------------|
| `external_layout_*` | Diseños de reportes personalizados |
| `l10n_pe_reports` | Reportes contables SUNAT |
| `l10n_pe_plame` | PLAME (Planilla Electrónica) |

#### Ventas

| Módulo | Descripción |
|--------|-------------|
| `sale_template_lines` | Plantillas de líneas de venta |
| `sales_prequotation` | Pre-cotizaciones |
| `sale_order_approval` | Aprobación de órdenes de venta |

#### Otros

| Módulo | Descripción |
|--------|-------------|
| `l10n_pe_libro_reclamaciones` | Libro de reclamaciones (obligatorio) |
| `apimigo_integration` | Integración con API Migo |
| `bo_apiservices_*` | Servicios de API |

### 1.2. l10n_pe_accounting (63 módulos)

Módulos contables específicos para Perú.

#### Contabilidad Base

| Módulo | Descripción |
|--------|-------------|
| `l10n_pe` | Plan contable general empresarial (PCGE) |
| `l10n_pe_chart_of_accounts` | Cuentas contables Perú |
| `l10n_pe_account_invoice` | Facturación contable |

#### Retenciones y Detracciones

| Módulo | Descripción |
|--------|-------------|
| `l10n_pe_detraccion` | Detracciones SUNAT (SPOT) |
| `l10n_pe_retentions` | Retenciones (agentes de retención) |
| `l10n_pe_perception` | Percepciones |

#### Reportes Contables

| Módulo | Descripción |
|--------|-------------|
| `l10n_pe_ledger` | Libro mayor |
| `l10n_pe_journal` | Libro diario |
| `l10n_pe_cash_book` | Libro de caja |
| `l10n_pe_inventory_kardex` | Kardex valorizado |

#### Utilidades

| Módulo | Descripción |
|--------|-------------|
| `one2many_search_widget` | Widget de búsqueda en one2many |
| `account_reconcile_ux` | UX mejorada para conciliación |

### 1.3. l10n_pe_hr (Recursos Humanos)

Módulos de RRHH específicos para Perú.

| Módulo | Descripción |
|--------|-------------|
| `l10n_pe_hr` | RRHH base Perú |
| `l10n_pe_hr_payroll` | Planilla de sueldos |
| `l10n_pe_hr_cts` | CTS (Compensación por Tiempo de Servicios) |
| `l10n_pe_hr_gratification` | Gratificaciones |
| `l10n_pe_hr_vacation` | Vacaciones |

---

## 2. OCA (Odoo Community Association)

### 2.1. manufacture (22 módulos)

Módulos de manufactura y producción.

#### Bill of Materials (BoM)

| Módulo | Descripción |
|--------|-------------|
| `mrp_bom_component_menu` | Menú de componentes de BoM |
| `mrp_bom_hierarchy` | Jerarquía de BoM |
| `mrp_bom_note` | Notas en BoM |
| `mrp_bom_tracking` | Tracking de BoM |

#### Producción

| Módulo | Descripción |
|--------|-------------|
| `mrp_production_note` | Notas en órdenes de producción |
| `mrp_production_grouped_by_product` | Agrupar por producto |
| `mrp_production_serial` | Números seriales en producción |
| `mrp_workorder_sequence` | Secuencia de órdenes de trabajo |

#### Quality Control

| Módulo | Descripción |
|--------|-------------|
| `quality_control` | Control de calidad |
| `quality_control_stock` | QC en stock |
| `quality_control_mrp` | QC en manufactura |

### 2.2. purchase-workflow (39 módulos)

Módulos de flujo de compras.

#### Órdenes de Compra

| Módulo | Descripción |
|--------|-------------|
| `purchase_order_approved` | Aprobación de OC |
| `purchase_order_approval_block` | Bloqueo de aprobación |
| `purchase_order_line_price_history` | Historial de precios |
| `purchase_force_invoiced` | Forzar facturación |

#### Requisiciones

| Módulo | Descripción |
|--------|-------------|
| `purchase_request` | Solicitudes de compra |
| `purchase_request_to_rfq` | RFQ desde solicitudes |
| `purchase_requisition` | Licitaciones de compra |

#### Integraciones

| Módulo | Descripción |
|--------|-------------|
| `purchase_stock_picking_return_invoicing` | Facturación de devoluciones |
| `purchase_tier_validation` | Validación por niveles |

### 2.3. server-tools

Herramientas de servidor.

| Módulo | Descripción |
|--------|-------------|
| `auditlog` | Registro de auditoría |
| `database_cleanup` | Limpieza de BD |
| `base_sparse_field` | Campos sparse |
| `base_technical_features` | Features técnicas |
| `date_range` | Rangos de fechas |
| `auto_backup` | Backup automático |
| `scheduler_error_mailer` | Email de errores cron |
| `base_jsonify` | Serialización JSON |

### 2.4. server-ux

Mejoras de UX.

| Módulo | Descripción |
|--------|-------------|
| `base_tier_validation` | Validación multi-nivel |
| `multi_step_wizard` | Wizards multi-paso |
| `date_range` | Selector de rangos de fecha |
| `mass_editing` | Edición masiva |
| `base_search_fuzzy` | Búsqueda fuzzy |

### 2.5. stock-logistics-workflow

Gestión de stock.

| Módulo | Descripción |
|--------|-------------|
| `stock_picking_batch_extended` | Batch picking extendido |
| `stock_move_line_auto_fill` | Auto-llenado de líneas |
| `stock_picking_invoicing` | Facturación desde picking |
| `stock_picking_return_lot` | Devoluciones con lotes |
| `stock_putaway_by_route` | Putaway por ruta |

---

## 3. Focuzai

Módulos enterprise de Focuzai.

- **Tamaño:** 117 MB
- **Contenido:** Extensiones enterprise de Odoo
- **Uso:** Módulos avanzados con licencia

---

## 4. Ganemo

Módulos personalizados de Ganemo.

- **Tamaño:** 81 MB
- **Contenido:** Módulos específicos del cliente
- **Uso:** Funcionalidades custom

---

## Gestión de Addons

### Estructura de Carpetas

```
odoo/
├── custom-addons/              # Tus addons personalizados (RW)
│   └── [vacío, listo para uso]
│
└── extra-addons/               # Addons de terceros (RO)
    ├── codlan-labs/
    │   ├── l10n_pe_base/
    │   ├── l10n_pe_accounting/
    │   └── l10n_pe_hr/
    ├── focuzai/
    ├── ganemo/
    └── OCA/
        ├── manufacture/
        ├── purchase-workflow/
        ├── server-tools/
        ├── server-ux/
        └── stock-logistics-workflow/
```

### Clonar Addons de Terceros

El archivo `odoo/third-party-addons.txt` define los repos a clonar:

```bash
# Formato:
# <public|private> <repo_url> <module1> <condition1> <module2> <condition2>

# Ejemplo:
enterprise https://github.com/focuz-ai/odoo-enterprise true
public https://github.com/OCA/manufacture.git mrp_bom_component_menu true
public https://github.com/odoocker/odoo-cloud-platform.git session_redis ${USE_REDIS}
```

**Ejecución:**
```bash
chmod +x odoo/clone-addons.sh
./odoo/clone-addons.sh
```

### Crear un Addon Personalizado

```bash
# 1. Acceder al contenedor
docker-compose exec -it -u root odoo bash

# 2. Navegar a custom-addons
cd /usr/lib/python3/dist-packages/odoo/custom-addons

# 3. Scaffold de addon
odoo scaffold my_custom_addon

# 4. Editar manifest
nano my_custom_addon/__manifest__.py
```

**Manifest Example:**
```python
{
    'name': 'My Custom Addon',
    'version': '17.0.1.0.0',
    'category': 'Custom',
    'summary': 'Custom functionality',
    'author': 'Your Company',
    'website': 'https://www.yourcompany.com',
    'license': 'LGPL-3',
    'depends': ['base', 'sale'],
    'data': [
        'security/ir.model.access.csv',
        'views/views.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
}
```

### Instalar Módulos

#### Método 1: Variables de Entorno

```bash
# En .env
INIT=module1,module2,module3

# Reiniciar Odoo
docker-compose restart odoo
```

#### Método 2: Odoo Shell

```bash
# Acceder a shell
docker-compose exec odoo bash
odoo shell -d my_database --http-port=8071

# En el shell
self.env['ir.module.module'].search([('name', '=', 'my_module')]).button_immediate_install()
self.env.cr.commit()
```

#### Método 3: Interfaz Web

```
Apps → Actualizar Lista de Apps → Buscar módulo → Instalar
```

### Actualizar Módulos

#### Método 1: Script odoo-update.sh

```bash
# Actualizar un módulo
./odoo/odoo-update.sh my_module

# Actualizar múltiples módulos
./odoo/odoo-update.sh module1,module2,module3

# Actualizar todos los módulos
./odoo/odoo-update.sh all
```

#### Método 2: Variable UPDATE

```bash
# En .env
UPDATE=module1,module2

# O actualizar todos
UPDATE=all

# Reiniciar
docker-compose restart odoo
```

### Desinstalar Módulos

```bash
# Odoo Shell
odoo shell -d my_database --http-port=8071

# En el shell
self.env['ir.module.module'].search([('name', '=', 'my_module')]).button_immediate_uninstall()
self.env.cr.commit()
```

---

## Dependencias entre Módulos

### Módulos Core de Odoo

```
base → web → portal → website
     → account → l10n_pe
     → sale → sale_management
     → purchase → purchase_requisition
     → stock → stock_account
     → mrp → mrp_account
```

### Módulos l10n_pe

```
l10n_pe_base
    ├─→ l10n_pe_edi_doc
    ├─→ l10n_pe_partner
    ├─→ l10n_pe_accounting
    │   ├─→ l10n_pe_detraccion
    │   └─→ l10n_pe_retentions
    └─→ l10n_pe_pos
        └─→ l10n_pe_pos_edi
```

---

## Testing de Módulos

### Test Tags

```bash
# En .env
APP_ENV=testing
TEST_TAGS=/module_name
ADDONS_TO_TEST=module1,module2

# Ejecutar
docker-compose up -d
```

### Test Manual

```bash
docker-compose exec odoo bash

odoo \
  --config /usr/lib/python3/dist-packages/odoo/odoo.conf \
  --database=test_mydb \
  --test-enable \
  --test-tags /my_module \
  --init=my_module \
  --workers=0 \
  --stop-after-init
```

---

## Best Practices

### 1. Organización de Addons

- **custom-addons/**: Solo tus addons personalizados
- **extra-addons/**: Addons de terceros (no modificar)
- Mantener estructura clara de carpetas

### 2. Versionado

```
17.0.1.0.0
│││││ │ │ └─ Patch
│││││ │ └─── Minor
│││││ └───── Major
│││└───────── Odoo version (17.0)
```

### 3. Dependencias

- Declarar todas las dependencias en `__manifest__.py`
- Evitar dependencias circulares
- Usar dependencias OCA cuando sea posible

### 4. Migraciones

- Crear carpetas `migrations/17.0.1.0.1/`
- Scripts `pre-migrate.py` y `post-migrate.py`
- Documentar cambios en el changelog

### 5. Testing

- Escribir tests para funcionalidad crítica
- Usar tags para organizar tests
- Test en ambiente de testing antes de staging

---

## Comandos Útiles

```bash
# Listar módulos instalados
docker-compose exec odoo odoo shell -d mydb --http-port=8071
>>> self.env['ir.module.module'].search([('state', '=', 'installed')]).mapped('name')

# Buscar módulos disponibles
>>> self.env['ir.module.module'].search([('name', 'ilike', 'l10n_pe')]).mapped('name')

# Ver dependencias de un módulo
>>> module = self.env['ir.module.module'].search([('name', '=', 'sale')])
>>> module.dependencies_id.mapped('name')

# Actualizar lista de apps
>>> self.env['ir.module.module'].update_list()
>>> self.env.cr.commit()
```

---

*Última actualización: 2025-10-27*
