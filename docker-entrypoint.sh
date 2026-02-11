#!/bin/bash
set -e

# 1. Start Postgres in the background temporarily
# We use -o to ignore external connections during setup
/usr/lib/postgresql/15/bin/postgres -D /data/postgres > /dev/null 2>&1 &
PID=$!

# 2. Wait for Postgres to be ready
echo "Waiting for Postgres to start..."
until /usr/lib/postgresql/15/bin/pg_isready -h localhost; do
  sleep 1
done

# 3. Create the role and database if they don't exist
echo "Initializing Spacebar role and database..."
psql -h localhost -U postgres -c "CREATE ROLE ${POSTGRES_USER} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';" || true
psql -h localhost -U postgres -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};" || true

# 4. Shut down the temporary background Postgres
kill $PID
wait $PID

echo "Postgres is initialized. Starting Supervisor..."
# 5. Start Supervisor (which will then start the permanent Postgres and Spacebar)
exec "$@"