#!/bin/bash

echo ===== superset =====
cd ~/git/superset
TAG=3.0.0rc2 docker-compose -f docker-compose-fcess.yml down

echo ===== thcu-tachikawa =====
cd ~/git/fcess-prjs/thcu-tachikawa-training
./fcess-backend/localdb stop

