#!/bin/bash

trap cleanup 1 2 3 6

cleanup()
{
  echo "Docker-Compose ... cleaning up."
  docker-compose down
  echo "Docker-Compose ... quitting."
  exit 1
}

set -e

if [ ! -d ./datadir ]
then
    mkdir -p datadir
    chmod -R 777 datadir
fi

docker-compose up --build
