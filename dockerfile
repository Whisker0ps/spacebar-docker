# Switching to Node 22 (more compatible with current Spacebar/SQLite builds)
FROM node:22-bookworm

WORKDIR /app

# Install system deps + python-is-python3 (vital for node-gyp/sqlite3)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      python-is-python3 \
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

# 1. Clean out any pre-existing junk that might be in the cloned repo
RUN rm -rf node_modules package-lock.json

# 2. Force the install using the specific python path
RUN npm install --ignore-scripts
RUN npm install sqlite3 --build-from-source --python=/usr/bin/python3

# 3. Build the app
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