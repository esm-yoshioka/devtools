#!/bin/bash

echo ===== superset =====
cd ~/git/superset
TAG=3.0.0rc2 docker-compose -f docker-compose-fcess.yml up -d

echo ===== thcu-tachikawa =====
cd ~/git/fcess-prjs/thcu-tachikawa-training
./fcess-backend/localdb start
MANIFEST_PATH=dist/application-manifest.yml java -jar dist/webapp.jar

