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
cd $GIT_HOME

cd fcess-api-spec
echo '===== api-spec ====='
git pull

cd ../fcess-frontend
echo '===== frontend ====='
git pull

cd ../fcess-backend
echo '===== backend ====='
git pull

cd ../fcess-manual
echo '===== manual ====='
git pull

cd ../fcess-manifest
echo '===== manifest ====='
git pull

cd ~/$GIT_HOME

