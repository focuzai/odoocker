#!/bin/bash

set -e

# Source environment variables
set -a
source .env
set +a

LOG_FILE=$(pwd)/odoo-update.log

# Función para escribir en el log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Función para enviar mensaje
msg() {
    local color=$1
    local msg=$2
    case $color in
        green) echo "\e[32m$msg\e[0m" ;;
        red) echo "\e[31m$msg\e[0m" ;;
        yelow) echo "\e[33m$msg\e[0m" ;;
        blue) echo "\e[34m$msg\e[0m" ;;
    esac
}
# Mostrar mensaje de odoo-update help
odoo_help() {
    if [ -f odoo/odoo-update.txt ]; then
        echo "$(cat odoo/odoo-update.txt)"
    else
        echo -e "Usage:\n  odoo-update [--help] [--container] [--database] <module>"
    fi
}
# Función para mostrar uso
uso() {
    odoo_help
    exit 1
}

# Variables por defecto
DB_NAME=$DB_NAME
CONTAINER_NAME=""

# Procesar argumentos
while getopts "d:c:h-:" opt; do
    case $opt in
        d) DB_NAME=$OPTARG ;;
        c) CONTAINER_NAME=$OPTARG ;;
        h) uso ;;
        -) case "$OPTARG" in
               help) uso ;;
               database) DB_NAME="$2"; shift ;;
               container) CONTAINER_NAME="$2"; shift ;;
               *) uso ;;
           esac ;;
        *) uso ;;
    esac
done

# Eliminar los argumentos procesados
shift $((OPTIND - 1))

# Verificar que los argumentos restantes sean correctos
if [ "$#" -ne 1 ]; then
    uso
fi

MODULES=$1

get_db() {
    local container_name=$1
    local db_name=""
    # Si no se proporcionó DB_NAME, obtenerlo del contenedor
    if [ -z "$container_name" ]; then
        db_name=$(docker compose exec odoo bash -c "awk -F '=' '/^db_name/ {print \$2}' $ODOO_RC | tr -d ' '")
    else
        db_name=$(docker exec $container_name bash -c "awk -F '=' '/^db_name/ {print \$2}' $ODOO_RC | tr -d ' '")
    fi

    # Si no se obtiene DB_NAME, obtenerlo del dominio principal
    if [ -z "$db_name" ]; then
        db_name=$DOMAIN0
    fi

    echo $db_name
}

# Si no se proporcionó CONTAINER_NAME, usar docker compose
if [ -z "$CONTAINER_NAME" ]; then
    # echo -e $(msg "blue" "No se proporcionó un contenedor, usando servicio Odoo con docker compose.")
    # Si no se proporcionó DB_NAME, obtenerlo del contenedor
    if [ -z "$DB_NAME" ]; then
        DB_NAME=$(get_db)
    fi
    if [ -z "$DB_NAME" ]; then
        echo -e $(msg "red" "🔴 No se pudo obtener el nombre de la base de datos desde la configuración de Odoo.")
        echo -e $(msg "yelow" "💡 Establecer el nombre de la base en el argumento -d | --database.")
        exit 1
    fi
    # Reiniciar contenedor de Odoo
    if docker compose restart --no-deps odoo; then
        echo -e $(msg "green" "🔄 Reinicio del contenedor Odoo exitoso.")
    else
        ERROR_MSG=$(docker compose restart --no-deps odoo 2>&1)
        echo -e $(msg "red" "🔴 Error al reiniciar el contenedor Odoo: $ERROR_MSG")
        exit 1
    fi

    # Ejecutar la actualización de módulos en el contenedor Docker
    # echo -e $(msg "green" "🚀 odoo -d $DB_NAME -u $MODULES")
    if docker compose exec odoo odoo -d $DB_NAME -u $MODULES --http-port=$DEBUG_PORT --stop-after-init; then
        echo -e $(msg "green" "👍 Actualización de módulos completada.")
    else
        echo -e $(msg "red" "🔴 Error al actualizar los módulos.")
    fi
else
    # Si no se proporcionó DB_NAME, obtenerlo del contenedor
    if [ -z "$DB_NAME" ]; then
        DB_NAME=$(get_db $CONTAINER_NAME)
    fi
    
    if [ -z "$DB_NAME" ]; then
        echo -e $(msg "red" "🔴 No se pudo obtener el nombre de la base de datos desde la configuración de Odoo.")
        echo -e $(msg "yelow" "💡 Establecer el nombre de la base en el argumento -d | --database.")
        exit 1
    fi
    
    # Reiniciar contenedor de Odoo
    if docker restart $CONTAINER_NAME; then
        echo -e $(msg "green" "🔄 Reinicio del contenedor Odoo exitoso.")
    else
        ERROR_MSG=$(docker restart $CONTAINER_NAME 2>&1)
        echo -e $(msg "red" "🔴 Error al reiniciar el contenedor Odoo: $ERROR_MSG")
        exit 1
    fi

    # Ejecutar la actualización de módulos en el contenedor Docker
    # echo -e $(msg "green" "🚀 odoo -d $DB_NAME -u $MODULES")
    if docker exec $CONTAINER_NAME odoo -d $DB_NAME -u $MODULES --http-port=$DEBUG_PORT --stop-after-init; then
        echo -e $(msg "green" "👍 Actualización de módulos completada.")
    else
        echo -e $(msg "red" "🔴 Error al actualizar los módulos.")
    fi
fi
