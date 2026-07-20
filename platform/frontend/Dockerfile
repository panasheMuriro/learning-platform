# Frontend Dockerfile — builds the React app and serves it with a simple static server.
# Used by docker-compose.yml for local development.

FROM oven/bun:1.3 AS builder

WORKDIR /build
COPY package.json bun.lockb* ./
RUN bun install
COPY . .
RUN bun run build

FROM nginx:alpine
COPY --from=builder /build/dist /usr/share/nginx/html
# Proxy /api and /ws to the backend container
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 3000
