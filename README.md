# devtools
開発環境とかツールとか覚書とか

## WSL2
- WSL2でのOSインストール
  - インストール可能なディストリビューションの確認  
  `wsl -l -o`
  - インストール
    - wsl --install -d [Distro_name]  
    `wsl --install -d ubuntu`
  - インストールされているディストリビューションを一覧表示  
  `wsl -l -v`
  - 指定したディストリビューションを停止
    - wsl -t [Distro_name]  
    `wsl -t develop`
  - バックアップ
    - wsl --export [Distro_name] [File]  
    `wsl --export ubuntu ubuntu_back_20220309.tar`
  - VMのインポート（別名での複写、他端末への移植）
    - wsl --import [Distro_name] [path] [data]  
    `wsl --import ubuntu_test .\wsl2\ubuntu_test .\ubuntu_back_20220309.tar`
  - 不要になったVMの削除
    - wsl --unregister [Distro_name]  
    `wsl --unregister ubuntu_test`

- .wslconfig
  - WSL2全体の設定を定義。%USERPROFILE%配下に格納  
  標準だとUSERPROFILEはC:\Users\[ユーザ名]
