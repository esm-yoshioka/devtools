#!/bin/bash

echo ===== superset =====
cd ~/git/superset
TAG=3.0.2 docker-compose -f docker-compose-non-dev.yml up -d

echo ===== standard =====
cd ~/git/fcess-prjs/trial
./fcess-backend/localdb start
MANIFEST_PATH=dist/application-manifest.yml java -jar dist/webapp.jar

