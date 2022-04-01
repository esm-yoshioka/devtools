#!/bin/sh

# このスクリプトの場所に移動
SCRIPT_DIR=$(cd $(dirname $(readlink -f $0 || echo $0));pwd -P)
cd ${SCRIPT_DIR}
cd ..

#フロントエンドを起動
sh -c "cd frontend; yarn; yarn serve;"

