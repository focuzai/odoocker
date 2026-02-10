ARG POSTGRES_TAG=17
FROM postgres:${POSTGRES_TAG}

ARG LOAD_LANGUAGE
ARG PGVECTOR_VERSION=0.8.1
ENV LOAD_LANGUAGE=${LOAD_LANGUAGE}

#------------------------#
#    APT Dependencies    #
#------------------------#
# Update apt packages and install extensions
RUN apt-get update && \
    apt-mark hold locales && \
    apt-get install -y --no-install-recommends \
        # Unaccent extension dependencies
        postgresql-contrib \
        apt-utils \
        # pgvector build dependencies (postgresql-server-dev from PGDG repo)
        build-essential \
        git \
        ca-certificates \
        postgresql-server-dev-${PG_MAJOR} && \
    # Clean up the apt cache to reduce the image size
    rm -rf /var/lib/apt/lists/*

#------------------------#
#    pgvector Extension  #
#------------------------#
# Build and install pgvector for AI/vector similarity search (required by Odoo 19 ai_app)
# Uses PG_CONFIG from the postgres image to get correct include paths
RUN cd /tmp && \
    git clone --branch v${PGVECTOR_VERSION} --depth 1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make clean && \
    make OPTFLAGS="" PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config && \
    make install PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config && \
    cd / && rm -rf /tmp/pgvector && \
    # Remove build dependencies to reduce image size
    apt-get update && \
    apt-get remove -y build-essential git postgresql-server-dev-${PG_MAJOR} && \
    apt-get autoremove -y && \
    apt-mark unhold locales && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=postgres:postgres ./.env /

# Copy the script to create the unaccent template and multi-user setup
COPY --chown=postgres:postgres ./postgres/entrypoint.sh /docker-entrypoint-initdb.d/entrypoint.sh

# Configure locale
RUN localedef -i ${LOAD_LANGUAGE} -c -f UTF-8 -A /usr/share/locale/locale.alias ${LOAD_LANGUAGE}.UTF-8

ENV LANG=${LOAD_LANGUAGE}.utf8
