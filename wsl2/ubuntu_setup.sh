#!/bin/bash
#
#   Ubuntu auto-setup shell
#
#     Author :esm-yoshioka
#     Target :ubuntu 26.04
#

set -euo pipefail

cd "$HOME" || exit 1
#=================================================
#   Parameter
#=================================================
IS_SETUP=true
IS_WSL2=true

IS_COMMON=false

IS_GIT=false
GIT_ID="esm-yoshioka"
GIT_MAIL="Mail Address"
GIT_DIR="git"
IS_GITNETRC=false
GIT_PASS="Personal Access Tokens"

IS_GH=false

IS_EMACS=false

IS_DOCKER=false
DOCKER_USER="$(id -un)"

IS_NODE=false
NVMVER="v0.40.7"
NODEVER="--lts"

#=================================================
#   Parameter check
#=================================================
if "$IS_GIT" ; then
    case "$GIT_MAIL" in
        ""|*\ *) echo "ERROR: GIT_MAIL を設定してください (現在: '$GIT_MAIL')" >&2; exit 1;;
    esac
    if "$IS_GITNETRC" ; then
        case "$GIT_PASS" in
            ""|*\ *) echo "ERROR: GIT_PASS を設定してください" >&2; exit 1;;
        esac
    fi
fi

#=================================================
#   Run check
#=================================================
echo '#-------------------------------------'
echo '  Install'
echo '   setup   =' $IS_SETUP
echo '   wsl2    =' $IS_WSL2
echo '   common  =' $IS_COMMON
echo '   ---'

echo '   git     =' $IS_GIT
if "$IS_GIT" ; then
    echo '     git id   = ' $GIT_ID
    echo '     git mail = ' $GIT_MAIL
    echo '     git dir  = ' $GIT_DIR
    if "$IS_GITNETRC"; then
        echo '     git pass =  (設定済み)'
    fi
fi

echo '   gh      =' $IS_GH

echo '   emacs   =' $IS_EMACS

echo '   docker  =' $IS_DOCKER
if "$IS_DOCKER" ; then
    echo '     docker run user = ' $DOCKER_USER
fi

echo '   node    =' $IS_NODE
if "$IS_NODE" ; then
    echo '     nvm version     = ' $NVMVER
    echo '     Node.js version = ' $NODEVER
fi

echo '#-------------------------------------'

while true ; do
    read -rp "Continue Setup?[y/N] " ans
    case "$ans" in
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

    # packages update
    sudo apt-get update
    sudo apt-get -yV upgrade

    # bash alias
    BASHFILE="$HOME/.bash_aliases"
    ALIAS_MARK='#User Alias setting'

    if grep -qF "$ALIAS_MARK" "$BASHFILE" 2>/dev/null ; then
        echo '  .bash_aliases は設定済みのためスキップします'
    else
        cat <<'EOF' >> "$BASHFILE"
#User Alias setting
alias lla='ls -alF'
alias ll='ls -lF'
winopen() {
    if [ -z "$1" ]; then
        echo "Usage: winopen <path or file>"
        return 0
    fi
    /mnt/c/Windows/System32/cmd.exe /c start "" "$(wslpath -w "$1")"
}
EOF
    fi

    # japanese environment
    sudo apt-get install -y language-pack-ja manpages-ja manpages-ja-dev

    sudo update-locale LANG=ja_JP.UTF-8

    if "$IS_WSL2" ; then
        # environment variable
        #   appendWindowsPath = false : Windows 側の PATH を引き継がない
        WSLFILE="/etc/wsl.conf"

        if sudo grep -q '^appendWindowsPath' "$WSLFILE" 2>/dev/null ; then
            echo '  /etc/wsl.conf [interop] は設定済みのためスキップします'
        else
            sudo tee -a "$WSLFILE" > /dev/null <<'EOF'

[interop]
appendWindowsPath = false
EOF
        fi

        if sudo grep -q '^systemd' "$WSLFILE" 2>/dev/null ; then
            echo '  /etc/wsl.conf [boot] は設定済みのためスキップします'
        else
            sudo tee -a "$WSLFILE" > /dev/null <<'EOF'

[boot]
systemd = true
EOF
        fi
    fi
fi

#=================================================
#   Setup Common tools
#=================================================
if "$IS_COMMON" ; then
    echo ''
    echo '===== common tools install ====='
    echo ''

    sudo apt-get install -y postgresql-client-18
fi

#=================================================
#   Git
#=================================================
if "$IS_GIT" ; then
    echo ''
    echo '===== git install ====='
    echo ''

    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt-get update
    sudo apt-get install -y git

    git config --global user.name "$GIT_ID"
    git config --global user.email "$GIT_MAIL"
    git config --global core.editor vim
    git config --global pull.rebase true

    if "$IS_GITNETRC"; then
        NETFILE="$HOME/.netrc"

        # PAT を平文で保持するため、書き込み前に 600 にしておく
        if [ ! -e "$NETFILE" ]; then
            touch "$NETFILE"
        fi
        chmod 600 "$NETFILE"

        if grep -q '^machine[[:space:]]\+github\.com' "$NETFILE" ; then
            echo '  .netrc の既存 github.com エントリを書き換えます'
            ( umask 077
              awk '/^machine[[:space:]]/ { skip = ($2 == "github.com") } !skip' \
                  "$NETFILE" > "${NETFILE}.tmp" )
            mv "${NETFILE}.tmp" "$NETFILE"
            chmod 600 "$NETFILE"
        fi

        {
            echo 'machine        github.com'
            echo "login          $GIT_ID"
            echo "password       $GIT_PASS"
        } >> "$NETFILE"
    fi

    mkdir -p "$GIT_DIR"
fi

#=================================================
#   GitHub CLI
#=================================================
if "$IS_GH" ; then
    echo ''
    echo '===== gh install ====='
    echo ''

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main
EOF

    sudo apt-get update
    sudo apt-get install -y gh

    echo '  gh の認証は再ログイン後に gh auth login を実行してください'
fi

#=================================================
#   Emacs
#=================================================
if "$IS_EMACS" ; then
    echo ''
    echo '===== emacs install ====='
    echo ''

    sudo apt-get remove -y emacs

    sudo snap wait system seed.loaded
    sudo snap install emacs --classic
    sudo apt-get install -y emacs-mozc-bin cmigemo ripgrep libtool-bin cmake

    mkdir -p .emacs.d
    mkdir -p .config
fi

#=================================================
#   Docker, Docker-compose
#=================================================
if "$IS_DOCKER" ; then
    echo ''
    echo '===== docker, docker-compose install ====='
    echo ''

    # docker
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg

    DOCKER_CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $DOCKER_CODENAME stable
EOF

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo usermod -aG docker "$DOCKER_USER"
    echo '  docker グループの反映には再ログイン (WSL2 の再起動) が必要です'
fi

#=================================================
#   Node
#=================================================
if "$IS_NODE" ; then
    echo ''
    echo '===== nvm, Node.js install ====='
    echo ''

    # nvm
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVMVER/install.sh" | bash
    . "$HOME/.nvm/nvm.sh"

    # nodejs
    nvm install "$NODEVER"
    nvm use "$NODEVER"

    if [ "$NODEVER" = "--lts" ]; then
        nvm alias default 'lts/*'
    else
        nvm alias default "$NODEVER"
    fi
fi

#=================================================
#   End
#=================================================
sudo apt-get -yV autoremove
sudo apt-get autoclean

mkdir -p work

echo ''
echo '====================================================='
echo '  Setup completed.'
echo ''
echo '  To apply /etc/wsl.conf and the docker group,'
echo '  restart WSL2. Run this command on Windows:'
echo ''
echo '      wsl --shutdown'
echo ''
echo '  Then start WSL2 again.'
echo '====================================================='
echo ''
