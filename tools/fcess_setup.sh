#!/bin/bash
#
#   F.CESS setup shell
#
#     Author :esm-yoshioka
#

cd ~
#=================================================
#   Parameter
#=================================================
GIT_HOME="git"
IS_JDK11=false
IS_NODEJS=false
NVMVER="v0.40.1"
NODEJSVER="18"
IS_YARN=false

#=================================================
#   OpenJDK11
#=================================================
echo '===== OpenJDK11 install ====='
    
sudo apt update
sudo apt -yV upgrade
sudo apt install -y openjdk-11-jdk

#=================================================
#   NVM, nodejs
#=================================================
echo '===== nvm, nodejs install ====='

# nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVMVER/install.sh | bash
. ~/.nvm/nvm.sh

# nodejs
nvm install $NODEJSVER

#=================================================
#   Yarn
#=================================================
echo '===== Yarn install ====='

npm install -g yarn

# update yarn
corepack enable
##  yarn set version 3.6.1
corepack prepare yarn@stable --activate

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
git clone https://github.com/esminc/fcess-prjs.git

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

# add needed tools
sudo apt install -y jq postgresql-client
