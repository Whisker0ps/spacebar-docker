# Debian-based Node image (required for native deps)
FROM node:20-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    supervisor \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Spacebar source (GitHub Actions clones it)
COPY . .

# Install Node deps
RUN npm install

# Build Spacebar
RUN npm run build

# Create postgres data dir
RUN mkdir -p /data/postgres && chown -R postgres:postgres /data

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Environment defaults (override in Unraid)
ENV POSTGRES_DB=spacebar
ENV POSTGRES_USER=spacebar
ENV POSTGRES_PASSWORD=spacebar
ENV POSTGRES_HOST=localhost
ENV POSTGRES_PORT=5432
ENV DB_TYPE=postgres
ENV PORT=3001

# Expose Spacebar port (container-side only)
EXPOSE 3001

# Supervisor is PID 1
CMD ["/usr/bin/supervisord", "-n"]
