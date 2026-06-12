#!/bin/sh

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: missing tag"
  exit 2
fi

op inject -i .env.prod -o .env.prod.tmp
op inject -i .env.migrate -o .env.migrate.tmp
trap "rm .env.prod.tmp .env.migrate.tmp && echo Cleaned up && exit" EXIT

set -a && . .env.prod.tmp && set +a

VERSION="$1"
TAG="rg.fr-par.scw.cloud/anders/anda:$VERSION"

docker buildx build --platform=linux/amd64 -t "$TAG" .
docker push "$TAG"
docker run --env-file .env.migrate.tmp "$TAG" /app/bin/migrate

CONTAINER_NAME=anda
CONTAINER_ID=$(scw container container list name=$CONTAINER_NAME -o template='{{.ID}}')

scw container container update "$CONTAINER_ID" \
image="$TAG" \
environment-variables.PHX_HOST=quiz.pndapetz.im \
secret-environment-variables.DATABASE_URL="$DATABASE_URL" \
secret-environment-variables.ACCESS_KEY_ID="$ACCESS_KEY_ID" \
secret-environment-variables.SECRET_ACCESS_KEY="$SECRET_ACCESS_KEY" \
secret-environment-variables.SECRET_KEY_BASE="$SECRET_KEY_BASE" \
secret-environment-variables.PROJECT_ID="$PROJECT_ID"

while
STATUS=$(scw container container list name=$CONTAINER_NAME -o template='{{.Status}}')
echo "Status: $STATUS"
[ "$STATUS" = 'updating' ]
do sleep 5; done