#!/bin/bash

NAME_IMAGE="sora-container-for-mac"
echo "Build Base Container-for-mac"

docker build -f common.dockerfile -t  ghcr.io/tatsuyai713/${NAME_IMAGE}:v0.03 .
docker push  ghcr.io/tatsuyai713/${NAME_IMAGE}:v0.03
