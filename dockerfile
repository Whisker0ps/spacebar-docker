# Use full Node.js LTS image (Debian Bookworm)
FROM node:20-bookworm

WORKDIR /app

# Install OS deps required for native Node modules (sqlite3)
# Added pkg-config to help npm find the sqlite libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      make \
      g++ \
      git \
      pkg-config \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy entrypoint
COPY docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

# Copy Spacebar source (GitHub Actions populates this)
COPY . .

# Install dependencies and force sqlite3 to build from source using the system libs
RUN npm install && npm install sqlite3 --build-from-source

# Build Spacebar
RUN npm run build

# --- Your Variables ---
ENV DB_TYPE=sqlite
ENV PORT=3001
ENV DB_PATH=/app/data/database.db
ENV POSTGRES_HOST=
ENV POSTGRES_PORT=5432
ENV POSTGRES_DB=
ENV POSTGRES_USER=
ENV POSTGRES_PASSWORD=
ENV API_ENDPOINT_PUBLIC=
ENV CDN_ENDPOINT_PUBLIC=
ENV GATEWAY_ENDPOINT_PUBLIC=

# Ensure the data directory exists for the sqlite file
RUN mkdir -p /app/data

EXPOSE 3001

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["npm", "run", "start"]