#!/bin/bash
#   Ubuntu auto-setup shell
#
#     Author :esm-yoshioka
#     Target :ubuntu 20.04 for WSL2

cd ~
#=================================================
#   Parameter
#=================================================
GITID="esm-yoshioka"
GITMAIL="*****@*****"
GITPASS="***********"



#=================================================
#   Change repository to Japan 
#=================================================
sudo sed -i.bak 's/\/\/archive.ubuntu.com/\/\/jp.archive.ubuntu.com/g' /etc/apt/sources.list

#=================================================
#   Packages update 
#=================================================
sudo apt -y update
sudo apt -yV upgrade

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
#   Git
#=================================================
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update
sudo apt -yV upgrade
git --version

git config --global user.name $GITID
git config --global user.email $GITMAIL

NETFILE=".netrc"
[ ! -e $NETFILE ] && touch $NETFILE
echo 'machine        github.com' >> $NETFILE
echo 'login          '$GITID >> $NETFILE
echo 'password       '$GITPASS >> $NETFILE

#=================================================
#   Emacs
#=================================================
sudo apt install -y emacs 

mkdir .emacs.d
cd .emacs.d
touch init.el

#=================================================
#   Other
#=================================================
cd ~
mkdir git
mkdir work

#=================================================
#   End
#=================================================
sudo apt -yV autoremove
sudo apt autoclean

echo '=== When the installation is completed, restart the WSL2. ==='
