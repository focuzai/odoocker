#!/bin/bash

# Archivo donde se guardarán los alias
BASHRC="$HOME/.bashrc"

# Declarar los alias en un array (clave=valor)
declare -A aliases=(
  ["odoo"]="cd ~/projects/odoo"
  ["hard-deploy"]="docker compose down && git pull && docker compose pull && docker compose build --no-cache && docker compose up -d && docker compose"
  ["deploy"]="docker compose down && git pull && docker compose up -d --build && docker compose logs -f --tail 2000 odoo"
  ["odoo-hard"]="docker compose build odoo --no-cache && docker compose up -d --no-deps --build odoo && docker compose logs -f --tail 2000 odoo"
  ["odoo-deploy"]="docker compose build odoo && docker compose up -d --no-deps --build odoo && docker compose logs -f --tail 2000 odoo"
  ["odoo-restart"]="docker compose restart --no-deps odoo"
  ["odoo-update"]="chmod +x odoo/odoo-update.sh && odoo/odoo-update.sh"
  ["psql"]="chmod +x postgres/psql.sh && postgres/psql.sh"
  ["logs"]="docker compose logs -f --tail 2000 odoo"
)

# Función para agregar o actualizar alias
update_alias() {
  local name="$1"
  local command="$2"
  
  # Si el alias ya existe, lo reemplaza; si no, lo agrega
  if grep -q "alias $name=" "$BASHRC"; then
    sed -i "/alias $name=/c\\alias $name='$command'" "$BASHRC"
    echo "🔄 Alias actualizado: $name"
  else
    echo "alias $name='$command'" >> "$BASHRC"
    echo "✅ Alias agregado: $name"
  fi
}

# Iterar sobre cada alias y actualizarlo en ~/.bashrc
echo "🔍 Configurando alias en $BASHRC..."
for name in "${!aliases[@]}"; do
  update_alias "$name" "${aliases[$name]}"
done

# Recargar ~/.bashrc para aplicar los cambios
source "$BASHRC"

echo "🎉 ¡Todos los alias han sido configurados y están listos para usar!"
