#!/bin/sh

# このスクリプトの場所に移動
SCRIPT_DIR=$(cd $(dirname $(readlink -f $0 || echo $0));pwd -P)
cd ${SCRIPT_DIR}
cd ..

mig_flg=0

while getopts "m" optKey; do
    case "$opeKey" in
        m)
            mig_flg=1
	    ;;
	*)
            ;;
    esac
done

# DB起動
./localdb start

# migrate
if [ $mig_flg = 1 ]; then
    echo '===== DB migrate ====='
    ./localdb migrate
fi

#バックエンドを起動
sh -c "./gradlew bootRun -p server/webapp"

