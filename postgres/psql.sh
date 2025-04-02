#!/bin/bash

set -e

# Source environment variables
set -a
source .env
set +a
# TODO: Agregar argumento para el ingreso de base de datos
POSTGRES_DB=$DB_NAME
docker compose exec postgres psql -p $POSTGRES_PORT -U $DB_USER -d $POSTGRES_DB