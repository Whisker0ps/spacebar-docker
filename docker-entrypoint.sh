#!/bin/bash
set -e

# 1. Start Postgres as the postgres user
echo "Starting temporary Postgres..."
su - postgres -c "/usr/lib/postgresql/15/bin/postgres -D /data/postgres" > /dev/null 2>&1 &
PID=$!

# 2. Wait for Postgres to be ready
until /usr/lib/postgresql/15/bin/pg_isready -h localhost; do
  echo "Waiting for Postgres to accept connections..."
  sleep 1
done

echo "Postgres is up. Creating role and database..."

# 3. Create the user and database
# We use '|| true' so it doesn't crash if they already exist on a restart
psql -h localhost -U postgres -c "CREATE ROLE ${POSTGRES_USER} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';" || true
psql -h localhost -U postgres -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};" || true

# 4. Shut down the temporary Postgres gracefully
echo "Cleaning up temporary process..."
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true

# 5. Hand over to Supervisor
echo "Initialization complete. Starting Supervisor..."
exec "$@"