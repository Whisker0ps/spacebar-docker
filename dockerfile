FROM node:20-bookworm

WORKDIR /app

# Install OS deps (Keep pkg-config, it's vital for SQLite)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      make \
      g++ \
      git \
      pkg-config \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

# Copy Spacebar source
COPY . .

# 1. Install dependencies but DON'T run build scripts yet (prevents early sqlite failure)
RUN npm install --ignore-scripts

# 2. Force install and REBUILD sqlite3 specifically
RUN npm install sqlite3 --build-from-source

# 3. Now run the rest of the build scripts
RUN npm run build

# --- Your Variables (Preserved) ---
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

RUN mkdir -p /app/data

EXPOSE 3001

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["npm", "run", "start"]