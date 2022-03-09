#!/bin/bash
#   Ubuntu auto-setup shell
#
#     Author :esm-yoshioka
#     Target :ubuntu 20.04 for WSL2

#=================================================
#   Change repository to Japan 
#=================================================
sudo sed -i.bak 's/\/\/archive.ubuntu.com/\/\/jp.archive.ubuntu.com/g' /etc/apt/sources.list

#=================================================
#   Packages update 
#=================================================
sudo apt -y update
sudo apt -yV upgrade
sudo apt -yV autoremove
sudo apt autoclean

#=================================================
#   Bash alias
#=================================================
BASHFILE=".bash_aliases"

if [ ! -e $BASHFILE ];then
	touch $BASHFILE
	echo '#User Alias setting' > $BASHFILE
fi
echo 'alias lla='\''ls -alF'\' >> $BASHFILE
echo 'alias ll='\''ls -lF'\' >> $BASHFILE

source .bashrc

#=================================================
#   Japanese environment
#=================================================
sudo apt install -y language-pack-ja
sudo apt install -y manpages-ja manpages-ja-dev

sudo update-locale LANG=ja_JP.UTF-8

#=================================================
#   Environment variable
#=================================================
WSLFILE="/etc/wsl.conf"

[ ! -e $WSLFILE ] && sudo touch $WSLFILE
sudo sh -c "echo '[interop]' >> $WSLFILE"
sudo sh -c "echo 'appendWindowsPath = false' >> $WSLFILE"

#=================================================
#   End
#=================================================
echo '=== When the installation is completed, restart the WSL. ==='
