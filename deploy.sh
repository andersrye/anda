#!/bin/sh

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: missing tag"
  exit 2
fi

op inject -i .env.prod -o .env.tmp
trap "rm .env.tmp && echo Cleaned up && exit" EXIT

set -a && . .env.tmp && set +a

VERSION="$1"
TAG="rg.fr-par.scw.cloud/anders/anda:$VERSION"

docker buildx build --platform=linux/amd64 -t "$TAG" .
docker push "$TAG"
docker run --env-file .env.tmp "$TAG" /app/bin/migrate

CONTAINER_NAME=anda
CONTAINER_ID=$(scw container container list name=$CONTAINER_NAME -o template='{{.ID}}')

scw container container update "$CONTAINER_ID" \
registry-image="$TAG" \
environment-variables.PHX_HOST=quiz.pndapetz.im \
secret-environment-variables.0.key=DATABASE_URL \
secret-environment-variables.0.value="$DATABASE_URL" \
secret-environment-variables.1.key=ACCESS_KEY_ID \
secret-environment-variables.1.value="$ACCESS_KEY_ID" \
secret-environment-variables.2.key=SECRET_ACCESS_KEY \
secret-environment-variables.2.value="$SECRET_ACCESS_KEY" \
secret-environment-variables.3.key=SECRET_KEY_BASE \
secret-environment-variables.3.value="$SECRET_KEY_BASE" \
secret-environment-variables.4.key=PROJECT_ID \
secret-environment-variables.4.value="$PROJECT_ID"

while
STATUS=$(scw container container list name=$CONTAINER_NAME -o template='{{.Status}}')
echo "Status: $STATUS"
[ "$STATUS" = 'pending' ]
do sleep 5; done