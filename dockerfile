# Use full Node.js LTS image (Debian-based)
FROM node:20

# Set working directory
WORKDIR /app

# Install OS deps needed for native modules like sqlite3
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      make \
      g++ \
      git \
    && rm -rf /var/lib/apt/lists/*

# Copy entrypoint
COPY docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

# Copy Spacebar source (GitHub Actions populates this)
COPY . .

# Install Spacebar dependencies
RUN npm install

# ✅ Explicitly install sqlite3 for fallback SQLite support
RUN npm install sqlite3

# Build Spacebar (schema, OpenAPI, etc.)
RUN npm run build

# Defaults (Unraid can override)
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

# Default exposed port (documentation only)
EXPOSE 3001

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["npm", "run", "start"]
