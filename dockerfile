FROM node:20-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    supervisor \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy your files (Protected by the rsync in Actions)
COPY . .

# Install and Build
RUN npm install
RUN npm run build

# Initialize Postgres data directory
RUN mkdir -p /data/postgres && chown -R postgres:postgres /data
USER postgres
RUN /usr/lib/postgresql/15/bin/initdb -D /data/postgres
USER root

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Environment defaults for Unraid
ENV POSTGRES_DB=spacebar
ENV POSTGRES_USER=spacebar
ENV POSTGRES_PASSWORD=spacebar
ENV PORT=3001

EXPOSE 3001

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]