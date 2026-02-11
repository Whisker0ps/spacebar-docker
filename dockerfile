#!/bin/sh
set -e

DB_FILE="/app/database.db"

# Helper function to update or insert endpoint
set_endpoint() {
  KEY=$1
  VALUE=$2
  if [ -z "$VALUE" ]; then
    return
  fi

  # If key exists, update it; if not, insert it
  EXISTS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='config';")
  if [ "$EXISTS" -eq 1 ]; then
    ROW=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM config WHERE key='$KEY';")
    if [ "$ROW" -eq 0 ]; then
      sqlite3 "$DB_FILE" "INSERT INTO config (key, value) VALUES ('$KEY', '\"$VALUE\"');"
    else
      sqlite3 "$DB_FILE" "UPDATE config SET value='\"$VALUE\"' WHERE key='$KEY';"
    fi
  fi
}

if [ ! -f "$DB_FILE" ]; then
  echo "Database not found. Initializing new Spacebar database..."
  
  # Let Spacebar create database by starting it briefly
  npm run build # ensure everything is built
  node -e "require('./dist/index.js')" &
  PID=$!
  
  # Give Spacebar a few seconds to initialize database
  sleep 5
  kill $PID || true
  echo "Database initialized."
fi

# Update endpoints if ENV variables are set
set_endpoint "api_endpointPublic" "$API_ENDPOINT_PUBLIC"
set_endpoint "cdn_endpointPublic" "$CDN_ENDPOINT_PUBLIC"
set_endpoint "gateway_endpointPublic" "$GATEWAY_ENDPOINT_PUBLIC"

echo "Starting Spacebar server..."
exec "$@"
