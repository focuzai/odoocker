#!/bin/bash

set -e

while IFS='=' read -r key value || [[ -n $key ]]; do
    # Skip comments and empty lines
    [[ $key =~ ^#.* ]] || [[ -z $key ]] && continue
    
    # Removing any quotes around the value
    value=${value%\"}
    value=${value#\"}
    
    # Declare variable
    eval "$key=\"$value\""
done < .env

# Check the USE_REDIS to add base_attachment_object_storage & session_redis to LOAD variable
if [[ $USE_REDIS == "true" ]]; then
    LOAD+=",session_redis"
fi

# Check the USE_REDIS to add attachment_s3 to LOAD variable
if [[ $USE_S3 == "true" ]]; then
    LOAD+=",base_attachment_object_storage"
    LOAD+=",attachment_s3"
fi

# Check the USE_REDIS to add sentry to LOAD variable
if [[ $USE_SENTRY == "true" ]]; then
    LOAD+=",sentry"
fi

# ================================
# Auto-provision PostgreSQL user (if POSTGRES_MAIN_USER is set)
# Creates DB_USER without SUPERUSER if it doesn't exist yet.
# ================================
if [ -n "$POSTGRES_MAIN_USER" ] && [ -n "$POSTGRES_MAIN_PASSWORD" ]; then
    echo "Checking if PostgreSQL user '${USER}' exists..."

    # Wait for PostgreSQL to be available (max 30s)
    RETRIES=30
    until PGPASSWORD="${POSTGRES_MAIN_PASSWORD}" psql -h "${HOST}" -p "${PORT}" -U "${POSTGRES_MAIN_USER}" -d postgres -c '\q' 2>/dev/null; do
        RETRIES=$((RETRIES - 1))
        if [ $RETRIES -le 0 ]; then
            echo "WARNING: Could not connect to PostgreSQL for user provisioning. Skipping."
            break
        fi
        echo "Waiting for PostgreSQL... ($RETRIES attempts left)"
        sleep 1
    done

    if [ $RETRIES -gt 0 ]; then
        # Helper: run psql as the main (admin) user
        pg_admin() {
            PGPASSWORD="${POSTGRES_MAIN_PASSWORD}" psql -h "${HOST}" -p "${PORT}" -U "${POSTGRES_MAIN_USER}" -d postgres "$@"
        }

        USER_EXISTS=$(pg_admin -tAc "SELECT 1 FROM pg_roles WHERE rolname='${USER}'")

        if [ "$USER_EXISTS" != "1" ]; then
            echo "Creating PostgreSQL user '${USER}' with CREATEDB (no SUPERUSER)..."
            pg_admin -c "CREATE USER ${USER} WITH PASSWORD '${PASSWORD}' CREATEDB;"
            pg_admin -c "GRANT CONNECT ON DATABASE ${DB_TEMPLATE} TO ${USER};"
            echo "User '${USER}' created successfully."
        else
            echo "User '${USER}' already exists. Skipping creation."
        fi

        # Pre-create database with CONNECT isolation (if DB_NAME is set)
        if [ -n "${DB_NAME}" ]; then
            DB_EXISTS=$(pg_admin -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")

            if [ "$DB_EXISTS" != "1" ]; then
                echo "Pre-creating database '${DB_NAME}' from template '${DB_TEMPLATE}'..."
                pg_admin -c "CREATE DATABASE \"${DB_NAME}\" TEMPLATE ${DB_TEMPLATE} OWNER ${USER};"
                echo "Database '${DB_NAME}' created."
            fi

            # Ensure CONNECT isolation: revoke PUBLIC, grant only to owner
            echo "Enforcing CONNECT isolation on '${DB_NAME}'..."
            pg_admin -c "REVOKE CONNECT ON DATABASE \"${DB_NAME}\" FROM PUBLIC;"
            pg_admin -c "GRANT CONNECT ON DATABASE \"${DB_NAME}\" TO ${USER};"
        fi
    fi
fi

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            # Creates new module.
            exec odoo "$@"
        else
            wait-for-psql.py --db_host ${HOST} --db_port ${PORT} --db_user ${USER} --db_password ${PASSWORD} --timeout=30

            if [ ${APP_ENV} = 'fresh' ] || [ ${APP_ENV} = 'restore' ]; then
                # Ideal for a fresh install or restore a production database.
                echo odoo --config ${ODOO_RC} --database= --init= --update= --load=${LOAD} --log-level=${LOG_LEVEL} --load-language= --workers=0 --limit-time-cpu=3600 --limit-time-real=7200

                exec odoo --config ${ODOO_RC} --database= --init= --update= --load-language= --workers=0 --limit-time-cpu=3600 --limit-time-real=7200
            fi

            if [ ${APP_ENV} = 'local' ] ; then
                # Listens to all .env variables mapped into odoo.conf file.
                echo odoo --config ${ODOO_RC} --database=${DB_NAME} --init=${INIT} --update=${UPDATE} --load=${LOAD} --workers=${WORKERS} --log-level=${LOG_LEVEL} --dev=${DEV_MODE}

                exec odoo --config ${ODOO_RC} --init=${INIT} --update=${UPDATE} --dev=${DEV_MODE}
            fi

            if [ ${APP_ENV} = 'debug' ] ; then
                # Same as local but you can debug you custom addons with your code editor (VSCode).
                echo debugpy odoo --config ${ODOO_RC}

                exec /usr/bin/python3 -m debugpy --listen ${DEBUG_INTERFACE}:${DEBUG_PORT} ${DEBUG_PATH} --config ${ODOO_RC}
            fi

            if [ ${APP_ENV} = 'testing' ] ; then
                # Initializies a fresh 'test_*' database, installs the addons to test, and runs tests you specify in the test tags.
                echo odoo --config ${ODOO_RC} --database=test_${DB_NAME} --test-enable --test-tags ${TEST_TAGS} --init=${ADDONS_TO_TEST} --update=${ADDONS_TO_TEST} --load=${LOAD} --log-level=${LOG_LEVEL} --without-demo= --workers=0 --dev= --stop-after-init

                exec odoo --config ${ODOO_RC} --database=test_${DB_NAME} --test-enable --test-tags ${TEST_TAGS} --init=${ADDONS_TO_TEST} --update=${ADDONS_TO_TEST} --without-demo= --workers=0 --dev= --stop-after-init
            fi

            if [ ${APP_ENV} = 'staging' ] ; then
                # Automagically upgrade all addons and install new ones. Ideal for deployment process.
                echo odoo --config ${ODOO_RC} --database=${DB_NAME} --init=${INIT} --update=all --load=${LOAD} --log-level=${LOG_LEVEL} --load-language=${LOAD_LANGUAGE} --limit-time-cpu=3600 --limit-time-real=7200 --dev=

                exec odoo --config ${ODOO_RC} --database=${DB_NAME} --init=${INIT} --update=all --without-demo=all --workers=0 --limit-time-cpu=3600 --limit-time-real=7200 --dev=
            fi

            if [ ${APP_ENV} = 'production' ] ; then
                # Bring up Odoo ready for production.
                echo odoo --config ${ODOO_RC} --database= --init=${INIT} --update=${UPDATE} --load=${LOAD} --workers=${WORKERS} --log-level=${LOG_LEVEL} --without-demo=${WITHOUT_DEMO} --load-language= --dev=

                exec odoo --config ${ODOO_RC} --database= --init=${INIT} --update=${UPDATE} --load-language= --dev=
            fi
        fi
        ;;
    -*)

        wait-for-psql.py --db_host ${HOST} --db_port ${PORT} --db_user ${USER} --db_password ${PASSWORD} --timeout=30
        echo odoo --config ${ODOO_RC}
        exec odoo --config ${ODOO_RC}
        ;;
    *)

        echo "$@"
        exec "$@"
esac

exit 1
