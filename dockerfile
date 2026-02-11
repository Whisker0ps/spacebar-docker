# Use Node.js LTS (Debian-based)
FROM node:20-slim

# Set working directory
WORKDIR /app

# Install build dependencies for native Node modules
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        python3 \
        git \
    && rm -rf /var/lib/apt/lists/*

# Copy wrapper files (entrypoint, package.json if needed)
COPY package*.json ./
COPY docker-entrypoint.sh ./docker-entrypoint.sh

# Install Node dependencies
RUN npm install --production

# Copy the rest of the app (we'll pull latest in GitHub Actions)
COPY . .

# Build Spacebar
RUN npm run build

# Make entrypoint executable
RUN chmod +x docker-entrypoint.sh

# Default environment variables
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

# Expose default Spacebar port
EXPOSE 3001

# Entrypoint
ENTRYPOINT ["./docker-entrypoint.sh"]

# Default command
CMD ["npm", "run", "start"]
