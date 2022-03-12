#!/bin/bash
#
#   Ubuntu auto-setup shell
#
#     Author :esm-yoshioka
#     Target :ubuntu 20.04 for WSL2
#

cd ~
#=================================================
#   Parameter
#=================================================
IS_SETUP=false
IS_GIT=false
GITID="esm-yoshioka"
GITMAIL="*****@*****"
GITPASS="***********"
IS_EMACS=false
IS_DOCKER=false
DOCKERUSER="*****"
DOCKERCOMPOSEVER="v2.3.3"

#=================================================
#   Run check
#=================================================
echo '#-------------------------------------'
echo '  Install'
echo '   setup  =' $IS_SETUP
echo '   git    =' $IS_GIT
echo '   emacs  =' $IS_EMACS
echo '   docker =' $IS_DOCKER
if "$IS_GIT" ; then
    echo ''
    echo '     git id = ' $GITID
    echo '     git mail = ' $GITMAIL
    echo '     git pass = ' $GITPASS
fi
if "$IS_DOCKER" ; then
    echo ''
    echo '     docker run user = ' $DOCKERUSER
    echo '     docker-compose version = ' $DOCKERCOMPOSEVER
fi
echo '#-------------------------------------'

while true ; do
    read -p "Continue Setup?[y/N]" ans
    case $ans in
	[yY])break;;
	*)exit;;
    esac
done

#=================================================
#   Setup WSL2
#=================================================
if "$IS_SETUP" ; then
    echo '=== setup wsl environment ==='

    # change repository to japan
    sudo sed -i.bak 's/\/\/archive.ubuntu.com/\/\/jp.archive.ubuntu.com/g' /etc/apt/sources.list

    # packages update
    sudo apt -y update
    sudo apt -yV upgrade

    # bash alias
    BASHFILE=".bash_aliases"

    if [ ! -e $BASHFILE ];then
	touch $BASHFILE
	echo '#User Alias setting' > $BASHFILE
    fi
    echo 'alias lla='\''ls -alF'\' >> $BASHFILE
    echo 'alias ll='\''ls -lF'\' >> $BASHFILE

    source .bashrc

    # japanese environment
    sudo apt install -y language-pack-ja
    sudo apt install -y manpages-ja manpages-ja-dev

    sudo update-locale LANG=ja_JP.UTF-8

    # environment variable
    WSLFILE="/etc/wsl.conf"

    [ ! -e $WSLFILE ] && sudo touch $WSLFILE
    sudo sh -c "echo '[interop]' >> $WSLFILE"
    sudo sh -c "echo 'appendWindowsPath = false' >> $WSLFILE"
fi

#=================================================
#   Git
#=================================================
if "$IS_GIT" ; then
    echo '=== git install ==='

    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt update
    sudo apt -yV upgrade
    git --version

    git config --global user.name $GITID
    git config --global user.email $GITMAIL
    git config --global core.editor vim

    NETFILE=".netrc"
    [ ! -e $NETFILE ] && touch $NETFILE
    echo 'machine        github.com' >> $NETFILE
    echo 'login          '$GITID >> $NETFILE
    echo 'password       '$GITPASS >> $NETFILE

    mkdir git
fi

#=================================================
#   Emacs
#=================================================
if "$IS_EMACS" ; then
    echo '=== emacs install ==='

    sudo apt update
    sudo apt -yV upgrade
    sudo apt install -y emacs

    mkdir .emacs.d
    cd .emacs.d
    touch init.el
fi

#=================================================
#   Docker, Docker-compose
#=================================================
if "$IS_DOCKER" ; then
    echo '=== docker, docker-compose install ==='

    sudo apt update
    sudo apt -yV upgrade
    sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    sudo usermod -aG docker $DOCKERUSER

##    sudo curl -L 'https://github.com/docker/compose/releases/download/'$DOCKERCOMPOSEVER'/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose
##    sudo chmod +x /usr/local/bin/docker-compose
fi

#=================================================
#   Other
#=================================================
cd ~
mkdir work

#=================================================
#   End
#=================================================
sudo apt -yV autoremove
sudo apt autoclean

echo '=== When the installation is completed, restart the WSL2. ==='
