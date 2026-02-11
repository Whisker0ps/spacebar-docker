#!/bin/bash
set -e

# 1. Start Postgres in background
echo "Starting temporary Postgres..."
su - postgres -c "/usr/lib/postgresql/15/bin/postgres -D /data/postgres" > /dev/null 2>&1 &
PID=$!

# 2. Wait for Postgres readiness
until /usr/lib/postgresql/15/bin/pg_isready -h localhost; do
  echo "Waiting for Postgres engine..."
  sleep 1
done

# 3. Setup Role, DB, and Permissions
echo "Configuring roles and schema ownership..."
psql -h localhost -U postgres -c "CREATE ROLE ${POSTGRES_USER} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';" || true
psql -h localhost -U postgres -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};" || true
psql -h localhost -U postgres -d ${POSTGRES_DB} -c "ALTER SCHEMA public OWNER TO ${POSTGRES_USER};"
psql -h localhost -U postgres -d ${POSTGRES_DB} -c "GRANT ALL ON SCHEMA public TO ${POSTGRES_USER};"

# 4. Background Seeder Logic
# This runs in the background so it can wait for Spacebar to create the tables
(
    echo "Seeder: Waiting for Spacebar to create the config table..."
    # Loop for 60 seconds max
    for i in {1..60}; do
        if psql -h localhost -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1 FROM config LIMIT 1;" >/dev/null 2>&1; then
            echo "Seeder: Config table found! Injecting Docker variables..."
            psql -h localhost -U ${POSTGRES_USER} -d ${POSTGRES_DB} <<EOF
            UPDATE config SET value = '"${API_ENDPOINT_PUBLIC}"' WHERE key = 'api_endpointPublic';
            UPDATE config SET value = '"${CDN_ENDPOINT_PUBLIC}"' WHERE key = 'cdn_endpointPublic';
            UPDATE config SET value = '"${GATEWAY_ENDPOINT_PUBLIC}"' WHERE key = 'gateway_endpointPublic';
            UPDATE config SET value = '"${CDN_ENDPOINT_PRIVATE}"' WHERE key = 'cdn_endpointPrivate';
            UPDATE config SET value = '"${GATEWAY_ENDPOINT_PRIVATE}"' WHERE key = 'gateway_endpointPrivate';
            UPDATE config SET value = '"${SERVER_NAME}"' WHERE key = 'general_serverName';
EOF
            echo "Seeder: Database successfully updated."
            break
        fi
        sleep 2
    done
) &

# 5. Hand over to Supervisor
# We DON'T kill Postgres here because Supervisor will manage the permanent processes
echo "Initialization logic set. Starting Supervisor..."
exec "$@"