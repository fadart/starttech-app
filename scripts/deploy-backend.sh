#!/bin/bash
set -e

ASG_NAME=$1
ECR_REGISTRY=$2
IMAGE_TAG=$3

if [ -z "$ASG_NAME" ] || [ -z "$ECR_REGISTRY" ] || [ -z "$IMAGE_TAG" ]; then
  echo "Usage: ./deploy-backend.sh <asg-name> <ecr-registry> <image-tag>"
  exit 1
fi

echo "==> Starting rolling deployment..."
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $ASG_NAME \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 120}'

echo "==> Waiting for refresh to complete..."
sleep 30

echo "==> Backend deployment initiated successfully."
echo "Image: $ECR_REGISTRY:$IMAGE_TAG"
echo "ASG: $ASG_NAME"
