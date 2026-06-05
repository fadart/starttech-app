#!/bin/bash
set -e

ALB_URL=$1
MAX_RETRIES=${2:-5}
RETRY_INTERVAL=${3:-10}

if [ -z "$ALB_URL" ]; then
  echo "Usage: ./health-check.sh <alb-url> [max-retries] [retry-interval]"
  exit 1
fi

echo "==> Running health check against $ALB_URL..."

for i in $(seq 1 $MAX_RETRIES); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" $ALB_URL/health)

  if [ "$STATUS" = "200" ]; then
    echo "Health check passed - status $STATUS"
    exit 0
  fi

  echo "Attempt $i/$MAX_RETRIES failed with status $STATUS, retrying in ${RETRY_INTERVAL}s..."
  sleep $RETRY_INTERVAL
done

echo "Health check failed after $MAX_RETRIES attempts"
exit 1
