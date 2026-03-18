# 🛠 Dotfiles Managed by Nix + Home Manager

Nix Flakes と Home Manager を使用した、ポータブルな開発環境設定です。
WSL2、Linux、macOS 等、ユーザー名が異なる環境でも --impure モードによって自動的に設定が最適化されます。

## 🚀 クイックスタート (新しい環境での構築)

### 1. リポジトリのクローン

```bash
git clone git@github.com:s-tatsuya/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Nix のインストール

```bash
make install
```

> **Note:** インストール完了後、画面の指示に従いターミナルを再起動するか、新しいシェルを開いてください。

### 3. home-manager のインストール

```bash
make setup-homemanager
```

> **Note:** インストール完了後、画面の指示に従いターミナルを再起動するか、新しいシェルを開いてください。

### 4. 設定の適用

```bash
make apply
```

---

## 🛠 日常の操作

| コマンド | 内容 |
| :--- | :--- |
| \`make apply\` | home.nix 等の変更をシステムに反映します。 |
| \`make update\` | ツールやプラグインのバージョンを最新に更新します。 |
| \`make clean\` | Nix の古い世代を削除してディスク容量を確保します。 |
| \`make help\` | 利用可能なコマンドの一覧を表示します。 |

---

## 📝 管理されている主なツール

- **Shell:** Fish (with Tide prompt & Fisher)
- **Editor:** Neovim
- **Multiplexer:** Zellij
- **Version Control:** Git (Nix 経由で global config を管理)

## ⚠️ 注意事項

- **Git Add:** Nix Flakes は Git 管理下のファイルのみを認識します。新しい設定ファイルを追加した後は、必ず \`git add\` を実行してから \`make apply\` してください。
- **SSH Keys:** セキュリティ上の理由から SSH 鍵はリポジトリに含めていません。新しい環境では別途 \`ssh-keygen\` を行い、GitHub 等へ登録してください。

## 参考資料

- [GitHub: DevContainerサンプル](https://github.com/search?q=org%3Amicrosoft+vscode-remote-try-&type=Repositories)
