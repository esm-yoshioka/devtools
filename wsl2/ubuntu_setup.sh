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
GIT_ID="esm-yoshioka"
GIT_MAIL="*****@*****"
GIT_PASS="***********"
IS_EMACS=false
IS_DOCKER=false
DOCKER_USER="*****"
DOCKER_COMPOSEVER="v2.2.3"
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
IS_JAVA=false

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
    echo '     git id = ' $GIT_ID
    echo '     git mail = ' $GIT_MAIL
    echo '     git pass = ' $GIT_PASS
fi
if "$IS_DOCKER" ; then
    echo ''
    echo '     docker run user = ' $DOCKER_USER
    echo '     docker-compose version = ' $DOCKER_COMPOSEVER
    echo '     docker config directory = ' $DOCKER_CONFIG
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

    git config --global user.name $GIT_ID
    git config --global user.email $GIT_MAIL
    git config --global core.editor vim

    NETFILE=".netrc"
    [ ! -e $NETFILE ] && touch $NETFILE
    echo 'machine        github.com' >> $NETFILE
    echo 'login          '$GIT_ID >> $NETFILE
    echo 'password       '$GIT_PASS >> $NETFILE

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

    # docker
    sudo apt update
    sudo apt -yV upgrade
    sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -SL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    sudo usermod -aG docker $DOCKER_USER

    # start docker service at startup
    sudo sh -c "echo 'none none rc defaults 0 0' >> /etc/fstab"
    sudo sh -c "echo '#!/bin/bash' > /sbin/mount.rc"
    sudo chmod +x /sbin/mount.rc
    sudo sh -c "echo 'service docker start' >> /sbin/mount.rc"
    sudo sh -c "echo 'mkdir -p /sys/fs/cgroup/systemd && mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd' >> /sbin/mount.rc"

    # docker-compoes
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/$DOCKER_COMPOSEVER/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
fi

#=================================================
#   Docker, Docker-compose
#=================================================
if "$IS_JAVA" ; then
    sudo apt update
    sudo apt -yV upgrade
    sudo apt install -y openjdk-11-jdk
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
