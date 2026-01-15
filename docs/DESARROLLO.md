# Guía de Desarrollo

Guía completa para desarrolladores que trabajan con el proyecto Equilux.pe.

## Tabla de Contenidos

1. [Setup Inicial](#setup-inicial)
2. [Estructura de Desarrollo](#estructura-de-desarrollo)
3. [Crear un Addon Personalizado](#crear-un-addon-personalizado)
4. [Hot-Reload y Debugging](#hot-reload-y-debugging)
5. [Odoo Shell](#odoo-shell)
6. [Testing](#testing)
7. [Git Workflow](#git-workflow)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Setup Inicial

### Requisitos Previos

- Docker 20.10+
- Docker Compose 2.0+
- Git
- VSCode (recomendado) con extensiones:
  - Python
  - Docker
  - Debugpy

### 1. Clonar el Repositorio

```bash
git clone https://github.com/[usuario]/equilux.pe.git
cd equilux.pe
```

### 2. Configurar Entorno

```bash
# Copiar .env.example
cp .env.example .env

# Editar .env
nano .env
```

**Configuración mínima para desarrollo:**

```env
APP_ENV=local
DB_NAME=my_dev_db
WORKERS=0
DEV_MODE=reload,qweb
LOG_LEVEL=debug
LIST_DB=True
WITHOUT_DEMO=
INIT=base,web,sale,purchase
```

### 3. Configurar Alias (Opcional pero Recomendado)

```bash
# Ejecutar script de alias
chmod +x setup-alias.sh
./setup-alias.sh

# Recargar shell
source ~/.bashrc  # o source ~/.zshrc

# Ahora puedes usar:
odoo          # cd al proyecto
deploy        # Deploy rápido
logs          # Ver logs
odoo-restart  # Reiniciar Odoo
```

### 4. Iniciar Proyecto

```bash
# Primera vez (build completo)
docker-compose up -d --build

# Ver logs
docker-compose logs -f odoo

# Acceder a Odoo
# http://localhost:8069
```

### 5. Crear Base de Datos

```
1. Ir a http://localhost:8069/web/database/manager
2. Master Password: odoo (valor de ADMIN_PASSWD en .env)
3. Database Name: my_dev_db
4. Email: admin@example.com
5. Password: admin
6. Language: Español (PE) / Spanish (PE)
7. Load demonstration data: ✅ (para desarrollo)
8. Click "Create Database"
```

---

## Estructura de Desarrollo

### Carpetas Importantes

```
/opt/projects/equilux.pe/
├── odoo/
│   ├── custom-addons/          # ← TUS ADDONS AQUÍ (read-write)
│   │   ├── my_module/
│   │   │   ├── __init__.py
│   │   │   ├── __manifest__.py
│   │   │   ├── models/
│   │   │   ├── views/
│   │   │   ├── security/
│   │   │   ├── data/
│   │   │   └── tests/
│   │   └── ...
│   │
│   ├── extra-addons/           # Addons de terceros (read-only)
│   │   ├── codlan-labs/
│   │   ├── OCA/
│   │   └── ...
│   │
│   ├── odoo.conf               # Configuración de Odoo
│   ├── requirements.txt        # Dependencias Python
│   ├── Dockerfile              # Imagen de Odoo
│   └── entrypoint.sh           # Entry point del contenedor
│
├── .vscode/
│   └── launch.json             # Configuración de debugging
│
├── docker-compose.yml          # Configuración de servicios
├── docker-compose.override.yml # Override local
└── .env                        # Variables de entorno
```

### Volúmenes Montados

| Ruta Local | Ruta Contenedor | Permisos |
|------------|-----------------|----------|
| `./odoo/custom-addons` | `/usr/lib/python3/dist-packages/odoo/custom-addons` | RW |
| `./odoo/extra-addons` | `/usr/lib/python3/dist-packages/odoo/extra-addons` | RO |
| `./odoo/odoo.conf` | `/etc/odoo/odoo.conf` | RO |

**Importante:** Solo `custom-addons/` tiene permisos de escritura.

---

## Crear un Addon Personalizado

### Método 1: Odoo Scaffold (Recomendado)

```bash
# 1. Acceder al contenedor como root
docker-compose exec -it -u root odoo bash

# 2. Navegar a custom-addons
cd /usr/lib/python3/dist-packages/odoo/custom-addons

# 3. Scaffold
odoo scaffold my_awesome_module

# 4. Salir del contenedor
exit
```

### Método 2: Crear Manualmente

```bash
# En tu máquina local
mkdir -p odoo/custom-addons/my_module
cd odoo/custom-addons/my_module
```

**Estructura mínima:**

```
my_module/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   └── my_model.py
├── views/
│   └── my_views.xml
└── security/
    └── ir.model.access.csv
```

### __manifest__.py

```python
{
    'name': 'My Awesome Module',
    'version': '17.0.1.0.0',
    'category': 'Custom',
    'summary': 'Short description of your module',
    'description': """
        Long description of your module.
        Multi-line supported.
    """,
    'author': 'Your Company',
    'website': 'https://www.yourcompany.com',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'sale',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/my_views.xml',
    ],
    'demo': [
        'demo/demo_data.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
}
```

### __init__.py (raíz)

```python
from . import models
```

### models/__init__.py

```python
from . import my_model
```

### models/my_model.py

```python
from odoo import models, fields, api

class MyModel(models.Model):
    _name = 'my_module.my_model'
    _description = 'My Model Description'

    name = fields.Char(string='Name', required=True)
    description = fields.Text(string='Description')
    active = fields.Boolean(string='Active', default=True)
    partner_id = fields.Many2one('res.partner', string='Partner')

    @api.depends('name')
    def _compute_display_name(self):
        for record in self:
            record.display_name = f"[{record.name}]"

    def action_do_something(self):
        self.ensure_one()
        # Your logic here
        return True
```

### views/my_views.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <!-- Tree View -->
    <record id="view_my_model_tree" model="ir.ui.view">
        <field name="name">my_module.my_model.tree</field>
        <field name="model">my_module.my_model</field>
        <field name="arch" type="xml">
            <tree>
                <field name="name"/>
                <field name="partner_id"/>
                <field name="active"/>
            </tree>
        </field>
    </record>

    <!-- Form View -->
    <record id="view_my_model_form" model="ir.ui.view">
        <field name="name">my_module.my_model.form</field>
        <field name="model">my_module.my_model</field>
        <field name="arch" type="xml">
            <form>
                <sheet>
                    <group>
                        <field name="name"/>
                        <field name="description"/>
                        <field name="partner_id"/>
                        <field name="active"/>
                    </group>
                </sheet>
            </form>
        </field>
    </record>

    <!-- Action -->
    <record id="action_my_model" model="ir.actions.act_window">
        <field name="name">My Models</field>
        <field name="res_model">my_module.my_model</field>
        <field name="view_mode">tree,form</field>
    </record>

    <!-- Menu -->
    <menuitem id="menu_my_module_root"
              name="My Module"
              sequence="10"/>

    <menuitem id="menu_my_model"
              name="My Models"
              parent="menu_my_module_root"
              action="action_my_model"
              sequence="10"/>
</odoo>
```

### security/ir.model.access.csv

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_my_model_user,my_module.my_model.user,model_my_module_my_model,base.group_user,1,1,1,0
access_my_model_manager,my_module.my_model.manager,model_my_module_my_model,base.group_system,1,1,1,1
```

### Instalar el Módulo

```bash
# Método 1: Actualizar lista de apps y instalar desde UI
# Apps → Update Apps List → Search "My Awesome Module" → Install

# Método 2: Variable INIT
# En .env:
INIT=my_module
# Reiniciar:
docker-compose restart odoo

# Método 3: Odoo Shell
docker-compose exec odoo odoo shell -d my_dev_db --http-port=8071
>>> self.env['ir.module.module'].search([('name', '=', 'my_module')]).button_immediate_install()
>>> self.env.cr.commit()
```

---

## Hot-Reload y Debugging

### Hot-Reload

Con `DEV_MODE=reload,qweb` en `.env`, Odoo recarga automáticamente:

- **Python (.py):** Cambios en modelos, controladores
- **XML (.xml):** Cambios en vistas
- **QWeb:** Templates web

**Requisitos:**
- `WORKERS=0` (obligatorio)
- `DEV_MODE=reload,qweb`

**No se recargan automáticamente:**
- CSS/JS (refrescar navegador con Ctrl+Shift+R)
- CSV de seguridad (requiere actualizar módulo)
- Manifest (requiere reiniciar Odoo)

### Debugging con VSCode

#### 1. Configurar .env

```env
APP_ENV=debug
WORKERS=0
LOG_LEVEL=debug
```

#### 2. Iniciar Odoo en modo debug

```bash
docker-compose down
docker-compose up -d --build
```

#### 3. Conectar Debugger

- Abrir VSCode
- Ir a Run and Debug (Ctrl+Shift+D)
- Seleccionar "Odoo: Attach"
- Presionar F5

#### 4. Colocar Breakpoints

- Abrir archivo en `odoo/custom-addons/my_module/models/my_model.py`
- Click en margen izquierdo para agregar breakpoint
- Ejecutar acción en Odoo que active el código

#### 5. Debug

- Variables: Ver valores en panel Variables
- Watch: Agregar expresiones a observar
- Call Stack: Ver stack de llamadas
- Console: Ejecutar código Python

**Comandos útiles en Debug Console:**

```python
# Ver valor de variable
self
self.env
self.name

# Ejecutar método
self.action_do_something()

# Buscar registros
self.env['res.partner'].search([])

# Obtener contexto
self.env.context
```

---

## Odoo Shell

El shell de Odoo permite ejecutar código Python directamente en el contexto de Odoo.

### Iniciar Shell

```bash
# Método 1: Desde contenedor
docker-compose exec odoo odoo shell -d my_dev_db --http-port=8071

# Método 2: Acceder a bash primero
docker-compose exec odoo bash
odoo shell -d my_dev_db --http-port=8071
```

### Comandos Útiles

```python
# Acceder al environment
self
self.env

# Buscar partners
partners = self.env['res.partner'].search([('is_company', '=', True)])
print(partners)

# Crear registro
partner = self.env['res.partner'].create({
    'name': 'Test Partner',
    'email': 'test@example.com',
})

# Actualizar registro
partner.write({'phone': '+51 999 999 999'})

# Eliminar registro
partner.unlink()

# Cambiar contraseña de usuario
user = self.env['res.users'].browse(2)  # Admin user ID=2
user.password = 'newpassword'
self.env.cr.commit()

# Cambiar login
user.login = 'newadmin'
self.env.cr.commit()

# Instalar módulo
module = self.env['ir.module.module'].search([('name', '=', 'sale')])
module.button_immediate_install()
self.env.cr.commit()

# Actualizar módulo
module = self.env['ir.module.module'].search([('name', '=', 'my_module')])
module.button_immediate_upgrade()
self.env.cr.commit()

# Listar módulos instalados
installed = self.env['ir.module.module'].search([('state', '=', 'installed')])
print(installed.mapped('name'))

# Ejecutar query SQL
self.env.cr.execute("SELECT * FROM res_partner LIMIT 5")
results = self.env.cr.fetchall()
print(results)

# Obtener contexto
print(self.env.context)

# Cambiar contexto
self = self.with_context(lang='en_US')

# Flush changes (sin commit)
self.env.flush_all()

# Commit
self.env.cr.commit()

# Rollback
self.env.cr.rollback()
```

---

## Testing

### Crear Tests

**Archivo:** `odoo/custom-addons/my_module/tests/__init__.py`

```python
from . import test_my_model
```

**Archivo:** `odoo/custom-addons/my_module/tests/test_my_model.py`

```python
from odoo.tests import TransactionCase, tagged

@tagged('post_install', '-at_install')
class TestMyModel(TransactionCase):

    def setUp(self):
        super().setUp()
        self.MyModel = self.env['my_module.my_model']
        self.partner = self.env['res.partner'].create({
            'name': 'Test Partner',
        })

    def test_create_my_model(self):
        """Test creating a record"""
        record = self.MyModel.create({
            'name': 'Test Record',
            'partner_id': self.partner.id,
        })
        self.assertTrue(record)
        self.assertEqual(record.name, 'Test Record')
        self.assertEqual(record.partner_id, self.partner)

    def test_action_do_something(self):
        """Test action method"""
        record = self.MyModel.create({
            'name': 'Test',
        })
        result = record.action_do_something()
        self.assertTrue(result)
```

### Ejecutar Tests

```bash
# Método 1: APP_ENV=testing
# En .env:
APP_ENV=testing
ADDONS_TO_TEST=my_module
TEST_TAGS=/my_module

docker-compose up -d
docker-compose logs -f odoo

# Método 2: Comando directo
docker-compose exec odoo bash
odoo \
  --config /etc/odoo/odoo.conf \
  --database=test_mydb \
  --test-enable \
  --test-tags /my_module \
  --init=my_module \
  --workers=0 \
  --stop-after-init

# Método 3: Test específico
odoo \
  --test-enable \
  --test-tags /my_module/tests/test_my_model \
  --database=test_mydb \
  --init=my_module \
  --workers=0 \
  --stop-after-init
```

### Tags de Test

```python
@tagged('post_install', '-at_install', 'my_custom_tag')
```

- `post_install`: Ejecutar después de instalar módulo
- `at_install`: Ejecutar durante instalación
- `-at_install`: NO ejecutar durante instalación
- Tags custom: Para agrupar tests

---

## Git Workflow

### Branching Strategy

```
main (producción)
  ├── develop (desarrollo)
  │   ├── feature/mi-funcionalidad
  │   ├── feature/otra-funcionalidad
  │   └── bugfix/correccion-bug
  ├── 17.0 (rama de versión Odoo 17)
  ├── 16.0 (rama de versión Odoo 16)
  └── hotfix/critical-fix (solo para producción)
```

### Workflow

```bash
# 1. Crear rama de feature
git checkout develop
git pull origin develop
git checkout -b feature/my-awesome-feature

# 2. Desarrollar
# ... cambios en código ...

# 3. Commit
git add .
git commit -m "feat: Add awesome feature"

# 4. Push
git push origin feature/my-awesome-feature

# 5. Crear Pull Request a develop

# 6. Después de merge, actualizar develop
git checkout develop
git pull origin develop

# 7. Merge a main (staging/production)
git checkout main
git pull origin main
git merge develop
git push origin main
```

### Commit Messages

Usar [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: Add new feature
fix: Fix bug
docs: Update documentation
style: Format code
refactor: Refactor code
test: Add tests
chore: Update dependencies
```

---

## Best Practices

### 1. Código Python

- Seguir [PEP 8](https://pep8.org/)
- Usar type hints cuando sea posible
- Documentar métodos con docstrings
- Validar datos de entrada
- Manejar excepciones apropiadamente

```python
from odoo import models, fields, api, exceptions

class MyModel(models.Model):
    _name = 'my.model'
    _description = 'My Model'

    name = fields.Char(required=True)

    @api.constrains('name')
    def _check_name(self):
        """Validate name is not empty"""
        for record in self:
            if not record.name or not record.name.strip():
                raise exceptions.ValidationError("Name cannot be empty")
```

### 2. Vistas XML

- Usar nombres descriptivos para IDs
- Agrupar campos relacionados
- Usar `attrs` para dinámicas
- Comentar secciones complejas

### 3. Seguridad

- Siempre definir `ir.model.access.csv`
- Usar `record rules` para restricciones por registro
- Validar permisos en métodos

### 4. Performance

- Usar `@api.depends` para campos compute
- Evitar loops anidados
- Usar `search_count()` en vez de `len(search())`
- Batch operations cuando sea posible

```python
# Mal
for record in records:
    record.write({'state': 'done'})

# Bien
records.write({'state': 'done'})
```

### 5. Traducciones

- Usar `_( )` para strings traducibles
- Generar archivos `.pot` para traducciones

```python
from odoo import _

raise exceptions.ValidationError(_("Error message"))
```

---

## Troubleshooting

### Error: Module not found

```bash
# 1. Verificar que el módulo existe
ls -la odoo/custom-addons/my_module

# 2. Actualizar lista de apps
# Apps → Update Apps List

# 3. Reiniciar Odoo
docker-compose restart odoo
```

### Error: Access rights

```bash
# Verificar ir.model.access.csv está en __manifest__.py
# Actualizar módulo
```

### Error: Import error

```bash
# Verificar __init__.py en todas las carpetas
# Verificar imports circulares
```

### Hot-reload no funciona

```bash
# Verificar en .env:
WORKERS=0
DEV_MODE=reload,qweb
```

### Debugger no conecta

```bash
# Verificar puerto 8070 está expuesto
docker-compose ps

# Verificar APP_ENV=debug
# Reiniciar contenedor
docker-compose restart odoo
```

---

*Última actualización: 2025-10-27*
