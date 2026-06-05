# Build stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git make

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Generate swagger docs and build binary
RUN go install github.com/swaggo/swag/cmd/swag@latest
RUN swag init -g ./cmd/api/main.go -o ./docs
RUN go build -o bin/much-to-do ./cmd/api/main.go

# Run stage
FROM alpine:3.18

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /app/bin/much-to-do .
COPY --from=builder /app/docs ./docs

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

# Run binary
CMD ["./much-to-do"]
