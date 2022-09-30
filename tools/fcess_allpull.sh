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

cd fcess-api-spec
echo '===== api-spec ====='
git pull

cd ../fcess-frontend
echo '===== api-frontend ====='
git pull

cd ../fcess-backend
echo '===== api-backend ====='
git pull

cd ../fcess-manual
echo '===== api-manual ====='
git pull

cd ../fcess-manifest
echo '===== api-manifest ====='
git pull

cd ~/$GIT_HOME

