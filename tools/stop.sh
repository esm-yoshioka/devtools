#!/bin/bash

echo ===== superset =====
cd ~/git/superset
TAG=3.0.2 docker-compose -f docker-compose-non-dev.yml down

echo ===== standard =====
cd ~/git/fcess-prjs/trial
./fcess-backend/localdb stop
