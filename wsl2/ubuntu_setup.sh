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

IS_SSHKEY=false
SSH_KEY_NAME="id_ed25519_github"

IS_GH=false

IS_EMACS=false

IS_DOCKER=false
DOCKER_USER="$(id -un)"

IS_NODE=false
NVMVER="v0.40.8"
NODEVER="--lts"

#=================================================
#   Parameter check
#=================================================
if "$IS_GIT" || "$IS_SSHKEY" ; then
    case "$GIT_MAIL" in
        ""|*\ *) echo "ERROR: GIT_MAIL を設定してください (現在: '$GIT_MAIL')" >&2; exit 1;;
    esac
fi

# 処理中に見つかった警告。最後にまとめて表示する
WARNINGS=()

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
fi

echo '   sshkey  =' $IS_SSHKEY
if "$IS_SSHKEY" ; then
    echo '     key file = ' "$HOME/.ssh/$SSH_KEY_NAME"
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

    # 旧方式（.netrc に PAT を平文保存）の残りがあれば警告
    if grep -q '^machine[[:space:]]\+github\.com' "$HOME/.netrc" 2>/dev/null ; then
        WARNINGS+=("$HOME/.netrc に github.com のエントリ (PAT) が残っています。削除し、GitHub 側でもトークンを Delete してください。")
    fi

    mkdir -p "$GIT_DIR"
fi

#=================================================
#   SSH key for GitHub (+ keychain)
#=================================================
if "$IS_SSHKEY" ; then
    echo ''
    echo '===== ssh key / keychain setup ====='
    echo ''

    sudo apt-get install -y openssh-client keychain curl jq

    SSH_DIR="$HOME/.ssh"
    SSH_KEY="$SSH_DIR/$SSH_KEY_NAME"
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    # --- 鍵の作成（パスフレーズは対話入力） ---
    if [ -e "$SSH_KEY" ]; then
        echo "  $SSH_KEY は作成済みのためスキップします"
    else
        echo '  SSH 鍵を作成します。パスフレーズを必ず設定してください（空にしない）'
        ssh-keygen -t ed25519 -C "$GIT_MAIL" -f "$SSH_KEY"
    fi
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"

    # パスフレーズなしで読めてしまう場合は警告
    if ssh-keygen -y -P "" -f "$SSH_KEY" > /dev/null 2>&1 ; then
        WARNINGS+=("$SSH_KEY にパスフレーズが設定されていません。ssh-keygen -p -f $SSH_KEY で設定してください。")
    fi

    SSH_CONFIG="$SSH_DIR/config"
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"

    if grep -qE '^Host[[:space:]]+github\.com([[:space:]]|$)' "$SSH_CONFIG" ; then
        echo '  ~/.ssh/config の github.com は設定済みのためスキップします'
    else
        cat <<EOF >> "$SSH_CONFIG"

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/$SSH_KEY_NAME
  IdentitiesOnly yes
  AddKeysToAgent yes
EOF
    fi

    # GitHub API から公式のホスト鍵を取得して登録
    KNOWN_HOSTS="$SSH_DIR/known_hosts"
    if ssh-keygen -F github.com -f "$KNOWN_HOSTS" > /dev/null 2>&1 ; then
        echo '  known_hosts の github.com は登録済みのためスキップします'
    else
        META_KEYS="$(curl -fsSL --proto '=https' --tlsv1.2 https://api.github.com/meta \
            | jq -r '.ssh_keys[]' \
            | grep -E '^(ssh-ed25519|ecdsa-sha2-nistp256|ssh-rsa) [A-Za-z0-9+/=]+$')" \
            || META_KEYS=""

        if [ -z "$META_KEYS" ]; then
            echo 'ERROR: GitHub API からホスト鍵を取得できませんでした。' >&2
            echo '       ネットワーク環境を確認するか、初回の ssh -T git@github.com で' >&2
            echo '       表示されるフィンガープリントを公式ドキュメントと手動で照合してください。' >&2
            exit 1
        fi

        touch "$KNOWN_HOSTS"
        chmod 644 "$KNOWN_HOSTS"
        printf '%s\n' "$META_KEYS" | sed 's/^/github.com /' >> "$KNOWN_HOSTS"

        echo '  github.com のホスト鍵（GitHub API より取得）を known_hosts に登録しました:'
        ssh-keygen -lF github.com -f "$KNOWN_HOSTS" | grep -v '^#' | sed 's/^/      /'
    fi

    # --- keychain（WSL 起動後の最初のシェルで 1 回だけパスフレーズ入力） ---
    BASHRC="$HOME/.bashrc"
    KEYCHAIN_MARK='# SSH agent (keychain)'

    if grep -qF "$KEYCHAIN_MARK" "$BASHRC" 2>/dev/null ; then
        echo '  .bashrc の keychain は設定済みのためスキップします'
    else
        cat <<EOF >> "$BASHRC"

$KEYCHAIN_MARK
eval "\$(keychain --eval --quiet $SSH_KEY_NAME)"
EOF
    fi
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

    gh config set git_protocol ssh
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

STEP=0
step() {
    STEP=$((STEP + 1))
    echo ''
    echo "  $STEP. $1"
}

echo ''
echo '====================================================='
echo '  Setup completed.'
echo '====================================================='

if [ "${#WARNINGS[@]}" -gt 0 ]; then
    echo ''
    echo '  [警告]'
    for w in "${WARNINGS[@]}"; do
        echo "   - $w"
    done
fi

echo ''
echo '  [この後に行う操作]'

if "$IS_SSHKEY" ; then
    step '公開鍵を GitHub に登録する（今のうちに実施可）'
    echo '     GitHub の Settings -> SSH and GPG keys -> New SSH key'
    echo '     Key type は Authentication Key、Key に以下を貼り付け:'
    echo ''
    sed 's/^/       /' "$HOME/.ssh/$SSH_KEY_NAME.pub"
fi

step 'WSL を再起動する（Windows の PowerShell で実行）'
echo '       wsl --shutdown'
echo '     その後、WSL を起動し直す'

if "$IS_SSHKEY" ; then
    step '最初のターミナルで SSH 鍵のパスフレーズを入力する'
    echo '     keychain が聞いてくるので入力。以降のターミナルでは聞かれない'
    if "$IS_EMACS" ; then
        echo '     Emacs はパスフレーズ入力後に起動する'
    fi

    step 'GitHub への SSH 接続を確認する'
    echo '       ssh-add -l'
    echo '       ssh -T git@github.com'
    echo '     パスフレーズなしで "Hi <ユーザー名>!" と表示されれば OK'
fi

if "$IS_GH" ; then
    step 'gh にログインする'
    echo '       gh auth login -h github.com -p ssh --skip-ssh-key -w'
    echo '     表示されたコードを https://github.com/login/device で入力し Authorize'

    step 'gh の設定を確認する'
    echo '       gh auth status'
    echo '     Git operations protocol が ssh、Token scopes に workflow が無いこと'
    echo '     workflow があれば:'
    echo '       gh auth refresh -h github.com --remove-scopes workflow'
fi

if "$IS_DOCKER" ; then
    step 'docker グループの反映を確認する'
    echo '       groups'
    echo '     docker が含まれていれば OK'
fi

echo ''
echo '====================================================='
echo ''
