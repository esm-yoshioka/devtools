#!/bin/bash
#
#   Ubuntu auto-setup shell
#
#     Author :esm-yoshioka
#     Target :ubuntu 22.04
#

cd ~
#=================================================
#   Parameter
#=================================================
IS_SETUP=true
IS_WSL2=true
IS_GIT=false
GIT_ID="esm-yoshioka"
GIT_MAIL="mail address"
GIT_DIR="git"
IS_GITNETRC=false
GIT_PASS="personal access tokens"
IS_EMACS=false
IS_DOCKER=false
DOCKER_USER="******"
IS_COMPOSE=false
DOCKER_COMPOSEVER="v2.24.6"
## DOCKER_COMPOSEVER="1.29.2"
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
IS_JDK11=false
IS_NODEJS=false
NVMVER="v0.39.7"
NODEJSVER="18"
IS_YARN=false

#=================================================
#   Run check
#=================================================
echo '#-------------------------------------'
echo '  Install'
echo '   setup   =' $IS_SETUP
echo '   wsl2    =' $IS_WSL2
echo '   git     =' $IS_GIT
echo '   emacs   =' $IS_EMACS
echo '   docker  =' $IS_DOCKER
echo '   compose =' $IS_COMPOSE
echo '   jdk11   =' $IS_JDK11
echo '   nodejs  =' $IS_NODEJS
echo '   yarn    =' $IS_YARN
if "$IS_GIT" ; then
    echo ''
    echo '     git id = ' $GIT_ID
    echo '     git mail = ' $GIT_MAIL
    echo '     git dir = ' $GIT_DIR
    if "$IS_GITNETRC"; then
        echo '     git pass = ' $GIT_PASS
    fi
fi
if "$IS_DOCKER" ; then
    echo ''
    echo '     docker run user = ' $DOCKER_USER
    if "$IS_COMPOSE" ; then
        echo '     docker-compose version = ' $DOCKER_COMPOSEVER
        echo '     docker config directory = ' $DOCKER_CONFIG
    fi
fi
if "$IS_NODEJS" ; then
    echo ''
    echo '     nvm version    = ' $NVMVER
    echo '     nodejs version = ' $NODEJSVER
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
#   Setup Ubuntu
#=================================================
if "$IS_SETUP" ; then
    echo '===== setup ubuntu environment ====='

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
    echo 'alias winopen='\''/mnt/c/Windows/SysWOW64/explorer.exe'\' >> $BASHFILE

    # japanese environment
    sudo apt install -y language-pack-ja
    sudo apt install -y manpages-ja manpages-ja-dev

    sudo update-locale LANG=ja_JP.UTF-8

    if "$IS_WSL2" ; then
	# environment variable
	WSLFILE="/etc/wsl.conf"
	
	[ ! -e $WSLFILE ] && sudo touch $WSLFILE
	sudo sh -c "echo '[interop]' >> $WSLFILE"
	sudo sh -c "echo 'appendWindowsPath = false' >> $WSLFILE"
    fi
fi

#=================================================
#   Git
#=================================================
if "$IS_GIT" ; then
    echo '===== git install ====='

    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt update
    sudo apt -yV upgrade

    git config --global user.name $GIT_ID
    git config --global user.email $GIT_MAIL
    git config --global core.editor vim
    git config --global pull.rebase true

    if "$IS_GITNETRC"; then
        NETFILE=".netrc"
        [ ! -e $NETFILE ] && touch $NETFILE
        echo 'machine        github.com' >> $NETFILE
        echo 'login          '$GIT_ID >> $NETFILE
        echo 'password       '$GIT_PASS >> $NETFILE
    fi

    mkdir $GIT_DIR
fi

#=================================================
#   Emacs
#=================================================
if "$IS_EMACS" ; then
    echo '===== emacs install ====='
    sudo apt remove -y emacs
    sudo apt -yV autoremove
    sudo apt autoclean
    sudo snap install emacs --classic

    [ ! -d .emacs.d ] && mkdir .emacs.d
    cd .emacs.d
    touch init.el

    cd ~
fi

#=================================================
#   Docker, Docker-compose
#=================================================
if "$IS_DOCKER" ; then
    echo '===== docker, docker-compose install ====='

    # setting for iptables
    echo '**********************************************************'
    echo '***  for Ubuntu22.04 or later, select iptables-legacy  ***'
    echo '**********************************************************'
    sudo update-alternatives --config iptables

    # docker
    sudo apt update
    sudo apt -yV upgrade
    sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    sudo usermod -aG docker $DOCKER_USER

    # docker-compoes
    if "$IS_COMPOSE" ; then
        if [ ${DOCKER_COMPOSEVER:0:2} = "1." ]; then
	    sudo curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSEVER/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
	    sudo chmod +x /usr/local/bin/docker-compose
        elif [ ${DOCKER_COMPOSEVER:0:2} = "v2" ]; then
	    mkdir -p $DOCKER_CONFIG/cli-plugins
	    curl -SL https://github.com/docker/compose/releases/download/$DOCKER_COMPOSEVER/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
	    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
        else
	    echo '!!!!!   Invalid docker-compose version  !!!!!'
        fi
    fi
fi

#=================================================
#   OpenJDK11
#=================================================
if "$IS_JDK11" ; then
    echo '===== OpenJDK11 install ====='
    
    sudo apt update
    sudo apt -yV upgrade
    sudo apt install -y openjdk-11-jdk
fi

#=================================================
#   NVM, nodejs
#=================================================
if "$IS_NODEJS" ; then
    echo '===== nvm, nodejs install ====='

    # nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVMVER/install.sh | bash
    . ~/.nvm/nvm.sh

    # nodejs
    nvm install $NODEJSVER
fi

#=================================================
#   Yarn
#=================================================
if "$IS_YARN" ; then
    echo '===== Yarn install ====='

    npm install -g yarn

    # update yarn
    corepack enable
    corepack prepare yarn@stable --activate
fi

#=================================================
#=================================================
#   Other
#=================================================
mkdir work

#=================================================
#   End
#=================================================
sudo apt -yV autoremove
sudo apt autoclean

echo '===== When the installation is completed, restart the WSL2. ====='

exec $SHELL --login
