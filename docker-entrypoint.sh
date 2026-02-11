#!/bin/bash
set -e

# 1. Start Postgres
echo "Starting temporary Postgres..."
su - postgres -c "/usr/lib/postgresql/15/bin/postgres -D /data/postgres" > /dev/null 2>&1 &
PID=$!

# 2. Wait for Postgres
until /usr/lib/postgresql/15/bin/pg_isready -h localhost; do
  echo "Waiting for Postgres..."
  sleep 1
done

# 3. Create Role/DB and Fix SCHEMA permissions
# By making the spacebar user the owner of the 'public' schema, 
# it has the right to create all its own tables (like 'templates').
echo "Setting up database and schema permissions..."
psql -h localhost -U postgres -c "CREATE ROLE ${POSTGRES_USER} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';" || true
psql -h localhost -U postgres -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};" || true
psql -h localhost -U postgres -d ${POSTGRES_DB} -c "ALTER SCHEMA public OWNER TO ${POSTGRES_USER};"
psql -h localhost -U postgres -d ${POSTGRES_DB} -c "GRANT ALL ON SCHEMA public TO ${POSTGRES_USER};"

# 4. Seed the config table (Only if it exists, otherwise Spacebar will create it on boot)
# We use a conditional check here to avoid the "Migration failed" loop.
echo "Checking for config table to seed..."
psql -h localhost -U postgres -d ${POSTGRES_DB} <<EOF
DO \$\$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'config') THEN
        INSERT INTO config (key, value) 
        VALUES 
            ('api_endpointPublic', '"${API_ENDPOINT_PUBLIC}"'),
            ('gateway_endpointPublic', '"${GATEWAY_ENDPOINT_PUBLIC}"'),
            ('cdn_endpointPublic', '"${CDN_ENDPOINT_PUBLIC}"')
        ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
    END IF;
END \$\$;
EOF

# 5. Shutdown
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true

echo "Permissions fixed. Starting Supervisor..."
exec "$@"