# Stage 1: Build
FROM node:20-alpine AS build

WORKDIR /app
RUN apk add --no-cache git

# Clone upstream repo and build
RUN git clone https://github.com/spacebarchat/server.git .
RUN npm install
RUN npm run build

# Stage 2: Run
FROM node:20-alpine

WORKDIR /app
RUN apk add --no-cache sqlite sqlite-dev

# Copy built app from build stage
COPY --from=build /app /app

EXPOSE 3001

# Optional environment variables for endpoints
ENV API_ENDPOINT_PUBLIC=""
ENV CDN_ENDPOINT_PUBLIC=""
ENV GATEWAY_ENDPOINT_PUBLIC=""

# Copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Use entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["npm", "run", "start"]
