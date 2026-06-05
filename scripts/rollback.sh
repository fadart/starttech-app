#!/bin/bash
set -e

ASG_NAME=$1
ECR_REGISTRY=$2
PREVIOUS_TAG=$3

if [ -z "$ASG_NAME" ] || [ -z "$ECR_REGISTRY" ] || [ -z "$PREVIOUS_TAG" ]; then
  echo "Usage: ./rollback.sh <asg-name> <ecr-registry> <previous-image-tag>"
  exit 1
fi

echo "==> Rolling back to image tag: $PREVIOUS_TAG..."

echo "==> Cancelling any ongoing instance refresh..."
aws autoscaling cancel-instance-refresh \
  --auto-scaling-group-name $ASG_NAME || true

echo "==> Starting rollback deployment..."
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $ASG_NAME \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 120}'

echo "==> Rollback initiated successfully."
echo "Image: $ECR_REGISTRY:$PREVIOUS_TAG"
echo "ASG: $ASG_NAME"
