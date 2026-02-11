# Debian-based Node image (required for native deps)
FROM node:20-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    supervisor \
    ca-certificates \
    git \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy everything (GitHub Actions handles the clone)
COPY . .

# Install Node deps - we use --force or clean install if necessary 
# because cloning upstream can sometimes leave lockfile conflicts
RUN npm install

# Build Spacebar
RUN npm run build

# --- Postgres Setup ---
# Create data dir and initialize the database cluster
RUN mkdir -p /data/postgres && chown -R postgres:postgres /data

# We must run initdb as the postgres user to create the system tables
USER postgres
RUN /usr/lib/postgresql/15/bin/initdb -D /data/postgres
USER root

# Copy supervisor config (Ensure this is in your repo)
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Environment defaults (Matches your Unraid requirements)
ENV POSTGRES_DB=spacebar
ENV POSTGRES_USER=spacebar
ENV POSTGRES_PASSWORD=spacebar
ENV POSTGRES_HOST=127.0.0.1
ENV POSTGRES_PORT=5432
ENV DB_TYPE=postgres
ENV PORT=3001

# Spacebar specific endpoints (often needed for full functionality)
ENV API_ENDPOINT_PUBLIC=
ENV CDN_ENDPOINT_PUBLIC=
ENV GATEWAY_ENDPOINT_PUBLIC=

# Expose Spacebar port
EXPOSE 3001

# Supervisor is PID 1, using the explicit config path
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]