#!/bin/bash

set -e

# Source environment variables
set -a
source /.env
set +a

# ================================
# 1. Create template DB with extensions
# ================================
echo "Creating template database: $DB_TEMPLATE ..."

psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "CREATE DATABASE $DB_TEMPLATE WITH TEMPLATE = template0;"
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $DB_TEMPLATE -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $DB_TEMPLATE -c "ALTER FUNCTION unaccent(text) IMMUTABLE;"
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $DB_TEMPLATE -c "CREATE EXTENSION IF NOT EXISTS vector;"

echo "Template database '$DB_TEMPLATE' created with extensions: unaccent, vector."

# ================================
# 2. Create users (multi-tenant support)
# ================================
# Function to create a user with CREATEDB + SUPERUSER and grant template access
create_user() {
    local user=$1
    local password=$2

    echo "Creating user: $user ..."

    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "CREATE USER $user WITH PASSWORD '$password' CREATEDB SUPERUSER;"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $DB_TEMPLATE TO $user;"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $DB_TEMPLATE -c "ALTER DATABASE $DB_TEMPLATE OWNER TO $user;"

    echo "User '$user' created with CREATEDB + SUPERUSER privileges."
}

# Check for numbered user variables (DB_USER_1, DB_USER_2, ...)
MULTI_USER_FOUND=false
for i in $(seq 1 20); do
    user_var="DB_USER_$i"
    pass_var="DB_PASSWORD_$i"
    user="${!user_var}"
    pass="${!pass_var}"

    if [ -n "$user" ] && [ -n "$pass" ]; then
        create_user "$user" "$pass"
        MULTI_USER_FOUND=true
    fi
done

# Fallback: if no numbered users found, use default DB_USER/DB_PASSWORD
if [ "$MULTI_USER_FOUND" = false ] && [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ]; then
    create_user "$DB_USER" "$DB_PASSWORD"
fi

# ================================
# 3. PgAdmin setup (optional)
# ================================
if [[ $USE_PGADMIN == "true" ]]; then
    echo "Setting up PgAdmin database ..."

    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "CREATE DATABASE $PGADMING_DB_NAME;"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "CREATE USER $PGADMING_DB_USER WITH PASSWORD '$PGADMIN_DB_PASSWORD';"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $PGADMING_DB_NAME TO $PGADMING_DB_USER;"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $PGADMING_DB_NAME -c "GRANT ALL PRIVILEGES ON SCHEMA public TO $PGADMING_DB_USER;"

    echo "PgAdmin database setup completed."
fi

echo "PostgreSQL initialization completed."
