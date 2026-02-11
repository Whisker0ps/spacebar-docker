#!/bin/sh
set -e

# Database file (SQLite)
DB_FILE="${DB_PATH:-/app/data/database.db}"
mkdir -p "$(dirname "$DB_FILE")"

# Helper function to update or insert endpoint (SQLite only)
set_endpoint() {
  KEY=$1
  VALUE=$2
  if [ -z "$VALUE" ]; then
    return
  fi

  if [ "$DB_TYPE" = "sqlite" ]; then
    EXISTS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='config';")
    if [ "$EXISTS" -eq 1 ]; then
      ROW=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM config WHERE key='$KEY';")
      if [ "$ROW" -eq 0 ]; then
        sqlite3 "$DB_FILE" "INSERT INTO config (key, value) VALUES ('$KEY', '\"$VALUE\"');"
      else
        sqlite3 "$DB_FILE" "UPDATE config SET value='\"$VALUE\"' WHERE key='$KEY';"
      fi
    fi
  fi
}

# Determine database backend
if [ "$DB_TYPE" = "postgres" ]; then
  if [ -z "$POSTGRES_HOST" ] || [ -z "$POSTGRES_DB" ] || [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
    echo "[ERROR] Postgres selected but required environment variables are missing."
    echo "Set POSTGRES_HOST, POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD"
    exit 1
  fi
  echo "[Database] Using PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
  export DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT:-5432}/${POSTGRES_DB}"
else
  echo "[Database] Using SQLite at $DB_FILE"
  export DATABASE_URL="sqlite://$DB_FILE"

  # Initialize SQLite if not exists
  if [ ! -f "$DB_FILE" ]; then
    echo "Database not found. Initializing new Spacebar SQLite database..."
    npm run build
    node -e "require('./dist/index.js')" &
    PID=$!
    sleep 5
    kill $PID || true
    echo "Database initialized."
  fi
fi

# Set endpoints (SQLite only)
set_endpoint "api_endpointPublic" "$API_ENDPOINT_PUBLIC"
set_endpoint "cdn_endpointPublic" "$CDN_ENDPOINT_PUBLIC"
set_endpoint "gateway_endpointPublic" "$GATEWAY_ENDPOINT_PUBLIC"

echo "Starting Spacebar server..."
exec "$@"
