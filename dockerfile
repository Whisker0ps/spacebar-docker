# Use full Node.js LTS image (Debian-based)
FROM node:20

WORKDIR /app

# Install OS deps required for native Node modules (sqlite3)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      make \
      g++ \
      git \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy entrypoint
COPY docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

# Copy Spacebar source (GitHub Actions populates this)
COPY . .

# Install Spacebar dependencies
RUN npm install

# Install sqlite3 explicitly for fallback SQLite support
RUN npm install sqlite3

# Build Spacebar
RUN npm run build

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

EXPOSE 3001

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["npm", "run", "start"]
