# devtools

## WSL2 memo
- WSL2でのOSインストール
  - ディストリビューションの確認
  `wsl --list --online`
  - インストール
    - wsl --install -d [Distro_name]
    `wsl --install -d ubuntu`
  - 不要になったVMの削除
    - wsl --unregister [Distro_name]
    `wsl --unregister ubuntu_test`
  - VMのインポート（別名での複写、他端末への移植）
    - wsl --import [Distro_name] [path] [data]
    `wsl --import ubuntu_test .\wsl2\ubuntu_test .\ubuntu_back_20220309.tar`
