# Use full Node.js LTS image (Debian-based) to avoid Alpine build issues
FROM node:20

# Set working directory
WORKDIR /app

# Install git (needed to clone upstream in GitHub Actions)
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

# Copy wrapper files (entrypoint and optionally package.json if you need them)
COPY docker-entrypoint.sh ./docker-entrypoint.sh
COPY package*.json ./  # optional if you have a wrapper package.json

# Make entrypoint executable
RUN chmod +x docker-entrypoint.sh

# Copy the rest of the app (GitHub Actions will populate this)
COPY . .

# Install all Node dependencies (including devDependencies needed for build)
RUN npm install

# Build Spacebar (schemas, OpenAPI, etc.)
RUN npm run build

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

# Expose the port
EXPOSE 3001

# Entrypoint
ENTRYPOINT ["./docker-entrypoint.sh"]

# Default command
CMD ["npm", "run", "start"]
