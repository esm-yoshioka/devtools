#!/bin/bash
#
#   Ubuntu auto-setup shell
#
#     Author :esm-yoshioka
#     Target :ubuntu 24.04
#

cd ~
#=================================================
#   Parameter
#=================================================
IS_SETUP=true
IS_WSL2=true

IS_GIT=false
GIT_ID="esm-yoshioka"
GIT_MAIL="Mail Address"
GIT_DIR="git"
IS_GITNETRC=false
GIT_PASS="Personal Access Tokens"

IS_EMACS=false

IS_DOCKER=false
DOCKER_USER="User Name"

#=================================================
#   Run check
#=================================================
echo '#-------------------------------------'
echo '  Install'
echo '   setup   =' $IS_SETUP
echo '   wsl2    =' $IS_WSL2
echo '   git     =' $IS_GIT
if "$IS_GIT" ; then
    echo '     git id   = ' $GIT_ID
    echo '     git mail = ' $GIT_MAIL
    echo '     git dir  = ' $GIT_DIR
    if "$IS_GITNETRC"; then
        echo '     git pass = ' $GIT_PASS
    fi
fi
echo '   emacs   =' $IS_EMACS
echo '   docker  =' $IS_DOCKER
if "$IS_DOCKER" ; then
    echo '     docker run user = ' $DOCKER_USER
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
    echo ''
    echo '===== setup ubuntu environment ====='
    echo ''

    # change repository to japan
    ## sudo sed -i.bak 's/\/\/archive.ubuntu.com/\/\/jp.archive.ubuntu.com/g' /etc/apt/sources.list

    # packages update
    sudo apt -y update
    sudo apt -yV upgrade

    # bash alias
    BASHFILE=".bash_aliases"

    if [ ! -e $BASHFILE ];then
        touch $BASHFILE
        echo '#User Alias setting' > $BASHFILE
    fi
cat <<'EOF' >> $BASHFILE
    alias lla='ls -alF'
    alias ll='ls -lF'
    winopen() {
        if [ -z "$1" ]; then
            echo "Usage: winopen <path or file>"
            return 0
        fi
        /mnt/c/Windows/SysWOW64/cmd.exe /c start "" "$(wslpath -w "$1")"
    }
EOF

    # japanese environment
    sudo apt install -y language-pack-ja manpages-ja manpages-ja-dev

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
    echo ''
    echo '===== git install ====='
    echo ''

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
    echo ''
    echo '===== emacs install ====='
    echo ''

    sudo apt remove -y emacs
    sudo apt -yV autoremove
    sudo apt autoclean
    sudo snap install emacs --classic
    sudo apt install -y emacs-mozc-bin cmigemo ripgrep libtool-bin cmake

    [ ! -d .emacs.d ] && mkdir .emacs.d
    [ ! -d .config ] && mkdir .config
fi

#=================================================
#   Docker, Docker-compose
#=================================================
if "$IS_DOCKER" ; then
    echo ''
    echo '===== docker, docker-compose install ====='
    echo ''

    # docker
    sudo apt update
    sudo apt -yV upgrade
    sudo apt install -y ca-certificates curl
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    sudo usermod -aG docker $DOCKER_USER

    # setting for iptables
    echo '**********************************************************'
    echo '***  for Ubuntu22.04 or later, select iptables-legacy  ***'
    echo '**********************************************************'
    sudo update-alternatives --config iptables
fi

#=================================================
#   End
#=================================================
sudo apt -yV autoremove
sudo apt autoclean

[ ! -d work ] && mkdir work

echo ''
echo '===== When the installation is completed, restart the WSL2. ====='
echo ''

exec $SHELL --login
