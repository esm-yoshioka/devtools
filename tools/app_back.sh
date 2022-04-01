#!/bin/sh

# このスクリプトの場所に移動
SCRIPT_DIR=$(cd $(dirname $(readlink -f $0 || echo $0));pwd -P)
cd ${SCRIPT_DIR}
cd ..

# DB起動
./localdb start

# migrate
./localdb migrate

#バックエンドを起動
sh -c "./gradlew bootRun -p server/webapp"

