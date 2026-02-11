#!/bin/bash
set -e

# 1. Start Postgres as the postgres user
echo "Starting temporary Postgres..."
su - postgres -c "/usr/lib/postgresql/15/bin/postgres -D /data/postgres" > /dev/null 2>&1 &
PID=$!

# 2. Wait for Postgres to be ready
until /usr/lib/postgresql/15/bin/pg_isready -h localhost; do
  echo "Waiting for Postgres..."
  sleep 1
done

# 3. Create the role and database
echo "Ensuring role and database exist..."
psql -h localhost -U postgres -c "CREATE ROLE ${POSTGRES_USER} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';" || true
psql -h localhost -U postgres -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};" || true

# 4. Seeding and Fixing Permissions
echo "Seeding database config and setting ownership..."
psql -h localhost -U postgres -d ${POSTGRES_DB} <<EOF
-- Ensure the config table exists
CREATE TABLE IF NOT EXISTS config (key text PRIMARY KEY, value text);

-- Fix ownership so the app user can actually use it
ALTER TABLE config OWNER TO ${POSTGRES_USER};
GRANT ALL PRIVILEGES ON TABLE config TO ${POSTGRES_USER};

-- Insert or Update the critical endpoints (JSON format)
INSERT INTO config (key, value) VALUES ('api_endpointPublic', '"${API_ENDPOINT_PUBLIC}"') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO config (key, value) VALUES ('gateway_endpointPublic', '"${GATEWAY_ENDPOINT_PUBLIC}"') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO config (key, value) VALUES ('cdn_endpointPublic', '"${CDN_ENDPOINT_PUBLIC}"') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
EOF

# 5. Shut down temporary Postgres
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true

echo "Database seeded and permissions fixed. Handing over to Supervisor..."
exec "$@"