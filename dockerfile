FROM node:20

WORKDIR /app

# Native build deps for sqlite3
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      make \
      g++ \
      git \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

COPY . .

# Install Spacebar deps
RUN npm install

# 🔑 Force sqlite3 to build from source (Node 20 fix)
RUN npm install sqlite3 --build-from-source

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
