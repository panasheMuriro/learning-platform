# Backend Dockerfile — builds the Go API server.
# Used by docker-compose.yml for local development.

FROM golang:1.22 AS builder

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o server ./cmd/server

FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    bash \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build/server .
RUN mkdir -p /data /home/student

EXPOSE 8080
CMD ["./server", "--addr", ":8080", "--content", "/content", "--lab-root", "/home/student", "--db", "/data/course.db"]
