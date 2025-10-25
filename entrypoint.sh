#!/bin/bash
set -e
echo "Running migrations"
COUNT=0
until /app/bin/migrate; do 
  echo "Migrations failed"
  ((COUNT++))
  if [  $COUNT -eq 10 ]; then
    echo "Failed to migrate after 10 attemps. Giving up."
    exit 2
  fi
  sleep 3
done

echo "Migrations done"
exec "$@"