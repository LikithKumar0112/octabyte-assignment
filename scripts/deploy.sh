#!/usr/bin/env bash
set -e 

ENV=$1
IMAGE=$2

if [ -z "$ENV" ] || [ -z "$IMAGE" ]; then
echo "usage: ./deploy.sh <staging|production> <image-uri>"
exit 1
fi

if [ "$ENV" = "staging" ]; then
PROJECT="my-project"
else
PROJECT="octabyte"
fi

else 
PROJECT="octabyte"
fi

CLUSTER="${PROJECT}-${ENV}-ecs-cluster"
SERVICE="${PROJECT}-${ENV}-app"
FAMILY="${PROJECT}-${ENV}-app"

aws ecs describe-task-definition --task-definition $FAMILY --query taskDefinition > task-def.json

jq --arg IMAGE "$IMAGE" '.containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
.compatibilities, .registeredAt, .registeredBy)' task-def.json > new-task-def.json

aws ecs register-task-definition --cli-input-json file://new-task-def.json

aws ecs update-service --cluster $CLUSTER --service $SERVICE --task-definition $FAMILY --force-new-deployment

aws ecs wait services-stable --cluster $CLUSTER --services $SERVICE
