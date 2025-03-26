#!/bin/bash

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
git status

cd ../fcess-frontend
echo '===== frontend ====='
git status

cd ../fcess-backend
echo '===== backend ====='
git status

cd ../fcess-manual
echo '===== manual ====='
git status

cd ../fcess-manifest
echo '===== manifest ====='
git status

cd ../fcess-prjs
echo '===== prjs ====='
git status

cd ~/$GIT_HOME
