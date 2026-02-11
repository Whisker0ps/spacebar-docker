# Use full Node.js image (Debian Bookworm)
FROM node:20-bookworm

# 1. Install system dependencies
# Added python-is-python3 and build-essential just in case of native modules
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    supervisor \
    ca-certificates \
    git \
    python-is-python3 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Copy source code (GitHub Actions populates this)
COPY . .

# 3. Build Spacebar
RUN npm install
RUN npm run build

# 4. Initialize Postgres Data Directory
# We must create the directory and let the postgres user own it
RUN mkdir -p /data/postgres && chown -R postgres:postgres /data
USER postgres
RUN /usr/lib/postgresql/15/bin/initdb -D /data/postgres
USER root

# 5. Prepare Configs & Scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# 6. Environment Defaults (Matches your Unraid/Local setup)
ENV POSTGRES_DB=spacebar
ENV POSTGRES_USER=spacebar
ENV POSTGRES_PASSWORD=spacebar
ENV PORT=3001

EXPOSE 3001

# The entrypoint script will create the user/db, then start Supervisor
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]