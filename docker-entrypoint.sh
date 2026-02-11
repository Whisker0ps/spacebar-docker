#!/bin/bash
set -e

# Define the data path clearly
PGDATA="/data/postgres"

# 1. Fix Permissions on boot
echo "Ensuring /data/postgres exists and has correct ownership..."
mkdir -p "$PGDATA"

# Only chown if necessary to save time/resources on large disks
if [ "$(stat -c '%u:%g' "$PGDATA")" != "999:999" ]; then
    chown -R postgres:postgres /data
fi

# Postgres is very picky; the data dir must be 700
chmod 700 "$PGDATA"

# 2. Initialize DB ONLY if empty
# We check for the 'base' folder, which is a better indicator of an initialized DB
if [ ! -d "$PGDATA/base" ]; then
    echo "No existing database found. Initializing new database in $PGDATA..."
    su - postgres -c "/usr/lib/postgresql/15/bin/initdb -D $PGDATA"
else
    echo "Found existing database in $PGDATA. Skipping initialization."
fi

# 3. Remove stale lock files
# This is crucial for persistence! If the container crashed, this file 
# prevents a restart.
rm -f "$PGDATA/postmaster.pid"

# 4. Background Seeder Logic
(
    echo "Seeder: Waiting for Postgres to start..."
    # We use -h /run/postgresql or -h localhost depending on your PG config
    until /usr/lib/postgresql/15/bin/pg_isready -h localhost -U postgres; do
        sleep 2
    done

    echo "Seeder: Postgres is up. Ensuring DB/User exist..."
    psql -h localhost -U postgres -c "CREATE ROLE ${POSTGRES_USER} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';" || true
    psql -h localhost -U postgres -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};" || true
    psql -h localhost -U postgres -d ${POSTGRES_DB} -c "ALTER SCHEMA public OWNER TO ${POSTGRES_USER};" || true

    echo "Seeder: Waiting for Spacebar to create tables..."
    for i in {1..30}; do
        if psql -h localhost -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1 FROM config LIMIT 1;" >/dev/null 2>&1; then
            echo "Seeder: Config table found! Injecting variables..."
            psql -h localhost -U ${POSTGRES_USER} -d ${POSTGRES_DB} <<EOF
            UPDATE config SET value = '"${API_ENDPOINT_PUBLIC}"' WHERE key = 'api_endpointPublic';
            UPDATE config SET value = '"${CDN_ENDPOINT_PUBLIC}"' WHERE key = 'cdn_endpointPublic';
            UPDATE config SET value = '"${GATEWAY_ENDPOINT_PUBLIC}"' WHERE key = 'gateway_endpointPublic';
            UPDATE config SET value = '"${SERVER_NAME}"' WHERE key = 'general_serverName';
            UPDATE config SET value = '"${CDN_ENDPOINT_PRIVATE}"' WHERE key = 'cdn_endpointPrivate';
EOF
            echo "Seeder: Complete."
            break
        fi
        sleep 3
    done
) &

# 5. Start Supervisor
echo "Starting Supervisor..."
exec "$@"