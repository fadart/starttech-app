#!/bin/bash
set -e

S3_BUCKET=$1
CLOUDFRONT_ID=$2
BUILD_DIR="Client/dist"

if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_ID" ]; then
  echo "Usage: ./deploy-frontend.sh <s3-bucket-name> <cloudfront-distribution-id>"
  exit 1
fi

echo "==> Building frontend..."
cd Client
npm ci
npm run build
cd ..

echo "==> Syncing files to S3..."
aws s3 sync $BUILD_DIR s3://$S3_BUCKET \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "index.html"

aws s3 cp $BUILD_DIR/index.html s3://$S3_BUCKET/index.html \
  --cache-control "no-cache, no-store, must-revalidate"

echo "==> Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id $CLOUDFRONT_ID \
  --paths "/*"

echo "==> Frontend deployed successfully."
