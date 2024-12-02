ARG KEYDB_TAG
FROM eqalpha/keydb:${KEYDB_TAG}

# Switch to root user
USER root

# Receive ARGs from docker-compose.yml & convert them into ENVs
ARG REDIS_CONFIG

ENV REDIS_CONFIG=${REDIS_CONFIG}

#-----------------------#
#       keydb Conf      #
#-----------------------#
# Copy environment variables & script to generate keydb.conf
WORKDIR /
COPY --chown=keydb:keydb --chmod=755 ./.env /
COPY --chown=keydb:keydb --chmod=755 ./redis/keydb.conf /
COPY --chown=keydb:keydb --chmod=755 ./redis/keydb.sh /

# Generate keydb.conf
RUN /keydb.sh && chown keydb:keydb ${REDIS_CONFIG}
RUN chown keydb:keydb /data

WORKDIR /data
