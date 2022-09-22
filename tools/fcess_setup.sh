#!/bin/bash
#
#   F.CESS setup shell
#     Author :esm-yoshioka
#

cd ~
#=================================================
#   Parameter
#=================================================
GIT_HOME="git"

#=================================================
#   F.CESS
#=================================================
echo '===== F.CESS install ====='

if [ ! -d $GIT_HOME ]; then
    mkdir -p $GIT_HOME
fi

# git clone
cd $GIT_HOME
git clone https://github.com/esminc/fcess-api-spec.git
git clone https://github.com/esminc/fcess-frontend.git
git clone https://github.com/esminc/fcess-backend.git
git clone https://github.com/esminc/fcess-manual.git
git clone https://github.com/esminc/fcess-manifest.git

# setup manifest
cd fcess-manifest
./docker/create-image
cd ..

# setup frontend
cd fcess-frontend/apispec
npm i
cd ..
yarn
cd ..

# setup backend
cd fcess-backend/apispec
npm i
cd ..
./localdb start

cd ~
