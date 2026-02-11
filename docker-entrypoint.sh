#!/bin/bash
set -e

# 1. Fix Permissions on boot
echo "Fixing permissions..."
mkdir -p /data/postgres
chown -R postgres:postgres /data
chmod 700 /data/postgres

# 2. Initialize DB if empty
if [ -z "$(ls -A /data/postgres)" ]; then
    echo "Initializing new database..."
    su - postgres -c "/usr/lib/postgresql/15/bin/initdb -D /data/postgres"
fi

# 3. Remove stale lock files (Fixes the FATAL: lock file error)
rm -f /data/postgres/postmaster.pid

# 4. Background Seeder Logic
# This waits for the main Postgres (started by Supervisor) to wake up
(
    echo "Seeder: Waiting for Postgres to start..."
    until /usr/lib/postgresql/15/bin/pg_isready -h localhost -U postgres; do
        sleep 1
    done

    echo "Seeder: Postgres is up. Ensuring DB/User exist..."
    psql -h localhost -U postgres -c "CREATE ROLE ${POSTGRES_USER} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';" || true
    psql -h localhost -U postgres -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};" || true
    psql -h localhost -U postgres -d ${POSTGRES_DB} -c "ALTER SCHEMA public OWNER TO ${POSTGRES_USER};" || true

    echo "Seeder: Waiting for Spacebar to create tables..."
    for i in {1..60}; do
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
        sleep 2
    done
) &

# 5. Start Supervisor (Which starts Postgres and Spacebar)
echo "Starting Supervisor..."
exec "$@"