#!/bin/bash
#
#   Ubuntu auto-setup shell
#
#     Author :esm-yoshioka
#     Target :ubuntu 22.04 for WSL2
#

cd ~
#=================================================
#   Parameter
#=================================================
IS_SETUP=false
IS_GIT=false
GIT_ID="esm-yoshioka"
GIT_MAIL="mail address"
GIT_PASS="personal access tokens"
GIT_DIR="~/git"
IS_EMACS=false
EMACSVER="28-nativecomp"
IS_DOCKER=false
DOCKER_USER="*****"
## DOCKER_COMPOSEVER="v2.10.0"
DOCKER_COMPOSEVER="1.29.2"
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
IS_JDK11=false
IS_NODEJS=false
NVMVER="v0.39.1"
NODEJSVER="12"
IS_YARN=false
IS_FCESS=false

#=================================================
#   Run check
#=================================================
echo '#-------------------------------------'
echo '  Install'
echo '   setup  =' $IS_SETUP
echo '   git    =' $IS_GIT
echo '   emacs  =' $IS_EMACS
echo '   docker =' $IS_DOCKER
echo '   jdk11  =' $IS_JDK11
echo '   nodejs =' $IS_NODEJS
echo '   yarn   =' $IS_YARN
echo '   f.cess =' $IS_FCESS
if "$IS_GIT" ; then
    echo ''
    echo '     git id = ' $GIT_ID
    echo '     git mail = ' $GIT_MAIL
    echo '     git pass = ' $GIT_PASS
    echo '     git dir = ' $GIT_DIR
fi
if "$IS_EMACS" ; then
    echo ''
    echo '     emacs version = ' $EMACSVER
fi
if "$IS_DOCKER" ; then
    echo ''
    echo '     docker run user = ' $DOCKER_USER
    echo '     docker-compose version = ' $DOCKER_COMPOSEVER
    echo '     docker config directory = ' $DOCKER_CONFIG
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
#   Setup WSL2
#=================================================
if "$IS_SETUP" ; then
    echo '===== setup wsl environment ====='

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
    echo '===== git install ====='

    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt update
    sudo apt -yV upgrade

    git config --global user.name $GIT_ID
    git config --global user.email $GIT_MAIL
    git config --global core.editor vim

    NETFILE=".netrc"
    [ ! -e $NETFILE ] && touch $NETFILE
    echo 'machine        github.com' >> $NETFILE
    echo 'login          '$GIT_ID >> $NETFILE
    echo 'password       '$GIT_PASS >> $NETFILE

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

    sudo add-apt-repository -y ppa:kelleyk/emacs
    sudo apt update
    sudo apt -yV upgrade
    sudo apt install -y emacs$EMACSVER

    mkdir .emacs.d
    cd .emacs.d
    touch init.el
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
fi

#=================================================
#   F.CESS
#=================================================
if "$IS_FCESS" ; then
    echo '===== f.cess install ====='

    if [ ! -d $GIT_DIR ]; then
	   mkdir $GIT_DIR 
    fi 
    
    # git clone
    cd $GIT_DIR 
    git clone https://github.com/esminc/fcess-api-spec.git
    git clone https://github.com/esminc/fcess-frontend.git
    git clone https://github.com/esminc/fcess-backend.git
    git clone https://github.com/esminc/fcess-manual.git
    git clone https://github.com/esminc/fcess-manifest.git
fi

#=================================================
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

echo '===== When the installation is completed, restart the WSL2. ====='

exec $SHELL --login
