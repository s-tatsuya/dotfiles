# M1 MacBook Pro をゼロから Nix で宣言的に管理する完全ガイド（2026年版）

## TL;DR

- クリーンな M1 Mac には **公式 NixOS インストーラ（Nix Installer Working Group が維持する foundation-owned fork、`artifacts.nixos.org/nix-installer` に `--enable-flakes` を付与）で上流 Nix を入れる**のが最も競合の少ない選択。上流 Nix なら nix-darwin の `nix.enable = true`（既定）のまま nix.conf を管理でき、過去に苦しんだ Determinate 起因の `nix.enable = false` 分岐を避けられる。
- nix-darwin は初回のみ `sudo nix run nix-darwin -- switch --flake ~/dotfiles#mac` でブートストラップし、以降は `sudo darwin-rebuild switch --flake ~/dotfiles#mac`。2025年の "The Plan" Phase 1（nix-darwin Issue #1457）以降、システムアクティベーションは root 実行が必須。home-manager は nix-darwin モジュールとして統合するのが現行推奨。
- dotfiles は `flake.nix` + `hosts/`（ホスト別）+ `modules/darwin`・`modules/home`（機能別モジュール）+ `home/<user>.nix` に分割するのがメンテしやすい。Homebrew は最初は入れず、必要になってから nix-homebrew で宣言的に管理すると Nix と競合しない。

## Key Findings

### 1. Nix 本体のインストール（2026年の推奨）

2026年半ば時点で macOS 用の主要なインストーラは 2 つある。

- **Determinate Systems インストーラ**（`curl -fsSL https://install.determinate.systems/nix | sh -s -- install`）は、**既定で Determinate Nix（下流ディストリビューション）をインストールする**。公式ブログ「Dropping upstream Nix from Determinate Nix Installer」（Graham Christensen, 2025年9月10日）によれば、デフォルトの Determinate Nix 切替は 2025年11月10日 に開始され、"Determinate Nix Installer will no longer prompt for Determinate Nix and will always install Determinate Nix. The `--prefer-upstream-nix` flag will no longer have an effect." とされている。つまり上流 Nix を選ぶ `--prefer-upstream-nix` フラグは README に残っているものの実質的に無効。Determinate Nix を使う場合、nix-darwin 側で必ず `nix.enable = false;` を設定しないとアクティベーションが中断する。
- **公式（上流）NixOS インストーラ**は `github.com/NixOS/nix-installer`（Nix Installer Working Group が維持する "foundation-owned fork"、Determinate インストーラのフォーク）で、`artifacts.nixos.org` から配信される。README の逐語どおり、既定では flakes / nix-command は有効化されないため `--enable-flakes` を付ける（`curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes`）。クリーンなアンインストーラ（`/nix/nix-installer uninstall`）を備える。

**このガイドの結論**：過去に Determinate と競合した経緯があり、かつ「default 設定でシンプルに動く」ことが目的なので、**公式 NixOS インストーラで上流 Nix を入れる**。こうすれば nix-darwin が Nix 設定を一元管理でき、`nix.enable` は既定の `true` のままでよい。

インストールコマンド：

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

マルチユーザー / シングルユーザーを聞かれたら **マルチユーザー**を選ぶ。完了後はシェルを開き直す。

### 2. flakes / nix-command 実験的機能の有効化

- 上記インストーラに `--enable-flakes` を付ければ `/etc/nix/nix.conf` に `experimental-features = nix-command flakes` が書き込まれる。
- 恒久的な管理は nix-darwin 側の `nix.settings.experimental-features = [ "nix-command" "flakes" ];` に集約するのがベスト。`darwin-rebuild switch` のたびに nix.conf が再生成される。

### 3. nix-darwin のブートストラップ

- nix-darwin には専用インストーラがなく、フレークを用意したうえで初回に次を実行する：
  ```bash
  sudo nix run nix-darwin -- switch --flake ~/dotfiles#mac
  ```
- これで `darwin-rebuild` コマンドが PATH に入る。以降の適用は **`sudo darwin-rebuild switch --flake ~/dotfiles#mac`**。nix-darwin Issue #1457「system activation must now be run as root」の逐語のとおり "nix-darwin has recently switched over to running the entire system activation process as root... you need to use `sudo darwin-rebuild switch` instead of `darwin-rebuild switch` from now on." であり、この変更は "The Plan" Phase 1（メンテナ emilazy）によるもの。関連する nix-homebrew Issue #60（2025年2月22日）にも "darwin-rebuild must now be run as root, the `system.activationScripts.{extraUserActivation,preUserActivation,postUserActivation}` settings have been removed" と記録されている。

### 4. home-manager の統合方式

- **nix-darwin モジュールとして統合する**（`home-manager.darwinModules.home-manager` を使う）のが現行の推奨。`darwin-rebuild switch` の一発でシステム設定とユーザー設定が同時に構築される。
- スタンドアロン（`home-manager` CLI を単体で使う）方式もあるが、システムとユーザーを別々に管理したい場合に限られる。統合方式では `home-manager.useGlobalPkgs = true;` と `home-manager.useUserPackages = true;` を設定する。
- `programs.home-manager.enable = true;` をユーザー設定に入れておくと、`home-manager` CLI 自体がユーザープロファイルに入り、`home-manager --version` などが実行可能になる。

### 5. Homebrew との競合回避

- 最初の最小構成では **Homebrew を入れない**。過去の競合は、Nix と Homebrew が両方 PATH を奪い合ったり、両方で同じツールを入れたことに起因することが多い。
- GUI アプリなどで Homebrew が必要になったら、`nix-homebrew`（`github:zhaofengli/nix-homebrew`）で Homebrew 本体をインストール・ピン留めし、`homebrew.casks` / `homebrew.brews` で宣言的に管理する。nix-darwin の `homebrew.enable = true` は Homebrew 本体をインストールしない点に注意（別途 nix-homebrew か手動インストールが必要）。

### 6. GitHub 認証方式（SSH ではなく gh CLI に一本化）

「HTTPS トークン / SSH 鍵 / gh CLI」は並列の選択肢ではない。**gh CLI 認証は HTTPS トークン認証そのもの**で、`gh auth login` が OAuth トークンを取得して macOS キーチェーンに保存し、`credential.helper = gh auth git-credential` を git に登録する。したがって実質の選択は SSH か HTTPS かであり、HTTPS を選ぶなら gh に任せるのが最も手数が少ない（PAT を手発行する方式は有効期限とスコープの管理が自分持ちになるだけ）。

**この構成で HTTPS + gh を採る理由：**

- **root 実行の副作用を構造的に回避できる**。Caveats に挙げた nix-darwin Issue #1471（`sudo darwin-rebuild` が root で走るため SSH 鍵が見つからない）は **SSH 固有**の摩擦。HTTPS + トークンなら `nix.settings.access-tokens` がシステム設定として効くので同じ問題が起きない。
- **flake input の取得と相性が良い**。未認証の GitHub API は 60 req/h でレート制限され、input 解決で引っかかる。これを解消する `access-tokens` はトークン方式でしか書けず、SSH 鍵では解決できない。プライベート flake を input に入れる場合も同様。
- **カバー範囲が広い**。SSH 鍵は git の push/pull しか賄わないが、gh は PR / Issue / Release / Actions・`gh api`・`gh extension` まで扱え、`gh auth token` で他ツールにトークンを渡せる。
- **ネットワーク耐性**。443 は塞がれないが 22 は社内 NW や公衆 Wi-Fi で塞がれることがある。

**SSH を併用する価値が出る場合**：コミット署名（`gpg.format = "ssh"` は GPG より運用が楽）、複数アカウントを `~/.ssh/config` のホスト別エイリアスで切り替えたい場合。いずれも現時点では不要なので鍵は作らない。

## Details

### 推奨ディレクトリ構成（dotfiles リポジトリ）

複数ファイルに分割してメンテしやすくする、コミュニティで一般的なフレーク構成：

```
~/dotfiles/
├── flake.nix                 # エントリポイント（inputs と darwinConfigurations）
├── flake.lock                # 依存の固定（自動生成）
├── README.md
├── hosts/
│   └── mac/
│       └── default.nix       # このホスト固有の nix-darwin 設定（primaryUser 等）
├── modules/
│   ├── darwin/               # nix-darwin（システム）用モジュール
│   │   ├── default.nix       # 集約（imports）
│   │   ├── nix.nix           # nix 設定・experimental-features
│   │   ├── system.nix        # macOS system.defaults / Touch ID
│   │   └── homebrew.nix      # （任意・後日）Homebrew 宣言
│   └── home/                 # home-manager（ユーザー）用モジュール
│       ├── default.nix       # 集約（imports）
│       ├── packages.nix      # ユーザーパッケージ
│       ├── git.nix           # アプリ別設定の例
│       └── zsh.nix
└── home/
    └── s-tatsuya.nix         # ユーザー固有の home-manager エントリ
```

新しいアプリ設定を足すときは `modules/home/<app>.nix` を作って `modules/home/default.nix` の imports に追加、システム機能なら `modules/darwin/<feature>.nix` を作って `modules/darwin/default.nix` に追加する。ホストを増やすときは `hosts/<name>/` を作り `flake.nix` の `darwinConfigurations` にエントリを足す。

### 最小構成の flake.nix

安定版 Nixpkgs 26.05 系列を使う例（unstable を使いたい場合は各 URL を `nixpkgs-unstable` / `master` / `release-26.05` の対応ブランチに変える）：

```nix
{
  description = "Tatsuya's macOS configuration (nix-darwin + home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager }:
  let
    username = "s-tatsuya";
    system = "aarch64-darwin";   # M1/M2/M3 は aarch64-darwin
  in
  {
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username; };
      modules = [
        ./hosts/mac/default.nix

        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs username; };
          home-manager.users.${username} = import ./home/${username}.nix;
        }
      ];
    };
  };
}
```

> 注：`darwin-rebuild switch --flake ~/dotfiles#mac` の `#mac` は、上の `darwinConfigurations."mac"` を指す。過去に使っていた `#mac` 出力名をそのまま踏襲できる。

### hosts/mac/default.nix

```nix
{ pkgs, username, ... }:
{
  imports = [
    ../../modules/darwin
  ];

  # sudo / Touch ID / homebrew などが適用される主ユーザー
  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Apple Silicon
  nixpkgs.hostPlatform = "aarch64-darwin";

  # 後方互換用。`darwin-rebuild changelog` を参照。
  # `nix flake init -t nix-darwin` が生成する現行値を使うのが安全。
  system.stateVersion = 6;
}
```

### modules/darwin/default.nix

```nix
{ ... }:
{
  imports = [
    ./nix.nix
    ./system.nix
  ];
}
```

### modules/darwin/nix.nix

```nix
{ ... }:
{
  # 公式（上流）インストーラで Nix を入れた場合はこのまま（既定 true）。
  # nix-darwin が /etc/nix/nix.conf を管理する。
  # ※ Determinate Nix を使う場合はここを false にすること。
  nix.enable = true;

  # flakes と nix-command を恒久的に有効化
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ストア自動最適化
  nix.optimise.automatic = true;

  # /etc/zshrc に nix-darwin 環境を読み込ませる
  programs.zsh.enable = true;
}
```

### modules/darwin/system.nix

```nix
{ ... }:
{
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
  };

  # Touch ID で sudo を解除（要再起動で有効化）
  security.pam.services.sudo_local.touchIdAuth = true;
}
```

### home/s-tatsuya.nix

```nix
{ pkgs, username, ... }:
{
  imports = [
    ../modules/home
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # 初回導入時のバージョン。基本的に変更しない。
  home.stateVersion = "26.05";

  # home-manager 自身を管理（CLI も利用可能になる）
  programs.home-manager.enable = true;
}
```

### modules/home/default.nix

```nix
{ ... }:
{
  imports = [
    ./packages.nix
    ./git.nix
    ./zsh.nix
  ];
}
```

### modules/home/packages.nix

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    tree
  ];
}
```

### modules/home/git.nix

```nix
{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Tatsuya";
    userEmail = "you@example.com";
  };
}
```

### modules/home/gh.nix

```nix
{ ... }:
{
  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
  };
}
```

`gitCredentialHelper.enable` は既定で `true` なので明示不要。これにより git 設定側へ次がマージされる：

```gitconfig
[credential "https://github.com"]
	helper = ""
	helper = "/nix/store/....-gh-2.96.0/bin/gh auth git-credential"
```

先頭の `helper = ""` が既存ヘルパー（macOS 既定の `osxkeychain`）を**該当ホストについてのみ**リセットするため、ヘルパーが二重登録されて認証情報が食い違うことはない。同じブロックが `https://gist.github.com` にも生成される。

トークン自体は宣言的に管理しない（フレークの内容は world-readable な Nix ストアにコピーされるため）。マシンごとに一度 `gh auth login` を実行する。

### modules/home/zsh.nix

```nix
{ ... }:
{
  # nix-darwin 側でも zsh を有効化しているが、home-manager 側でも
  # 有効化すると direnv などのフックが確実に挿入される。
  programs.zsh.enable = true;
}
```

## Recommendations（手順：クリーンな Mac → 動作確認まで）

**Step 0 — Mac の初期化**
「システム設定 → 一般 → 転送またはリセット → すべてのコンテンツと設定を消去」で初期化するか、リカバリで macOS を再インストールする。

**Step 1 — 初期セットアップと git**
macOS の初期設定でユーザー `s-tatsuya` を作成。ターミナルで Xcode コマンドラインツール（git を含む）を入れる：

```bash
xcode-select --install
```

**Step 2 — Nix をインストール（上流 + flakes）**

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

マルチユーザーを選択。完了後、ターミナルを開き直して確認：

```bash
nix --version
nix run nixpkgs#hello        # Hello, world! が出れば OK
```

**Step 3 — dotfiles リポジトリを作る**

```bash
mkdir -p ~/dotfiles
cd ~/dotfiles
git init
# 上記の flake.nix / hosts / modules / home を作成
git add .                    # ★フレークは git 追跡下のファイルしか見ないので必須
```

**Step 4 — nix-darwin をブートストラップ**

```bash
sudo nix run nix-darwin -- switch --flake ~/dotfiles#mac
```

`/etc/zshrc` などの既存ファイルで衝突警告が出たら、退避してから再実行：

```bash
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
```

**Step 5 — 動作確認**
新しいターミナルを開いて：

```bash
which darwin-rebuild
darwin-rebuild --version
darwin-rebuild --list-generations
home-manager --version       # programs.home-manager.enable = true; により利用可能
nix --version
```

**Step 6 — GitHub 認証（マシンごとに1回）**
トークンはリポジトリに置けないので、ここだけは手作業になる（SSH 鍵を配れないのと同じ）。

```bash
gh auth login                        # HTTPS → ブラウザ認証 を選択
gh auth status
git config --get-regexp '^credential\.'   # gh のヘルパーが登録されているか確認
git ls-remote https://github.com/s-tatsuya/dotfiles.git >/dev/null && echo OK
```

flake input の取得で GitHub API のレート制限（未認証は 60 req/h）に当たる場合や、プライベート flake を input にする場合は access-token を設定する。トークンをフレークに直書きすると world-readable な Nix ストアに載るので、git 管理外のファイルを include する：

```nix
# modules/darwin/nix.nix
nix.extraOptions = ''
  !include /etc/nix/secret.conf
'';
```

```bash
sudo sh -c 'echo "access-tokens = github.com=$(gh auth token)" > /etc/nix/secret.conf'
sudo chmod 600 /etc/nix/secret.conf
```

**Step 7 — 以降の運用**
設定を変えたら：

```bash
sudo darwin-rebuild switch --flake ~/dotfiles#mac
```

依存を更新したいときは `nix flake update` を実行してから switch する。

**運用を変える閾値：**

- Homebrew でしか入らない GUI アプリが必要になったら → `nix-homebrew` を inputs に追加して宣言的管理へ移行。
- 複数 Mac / Linux を管理し始めたら → `hosts/` にエントリを追加し、`modules/home` を共通化。
- ビルドが極端に遅い（LLVM 等をソースビルドしてしまう）なら → `nixpkgs` の URL を `nixos-*` ではなく `nixpkgs-*-darwin` チャンネルに固定（Darwin バイナリがキャッシュされている）。

## Caveats

- **`system.stateVersion` の値**：`nix flake init -t nix-darwin` が生成する現行値を使うのが最も安全。ここでは 6 を例示したが、導入時のテンプレート値に合わせること。一度決めたら基本的に変更しない。
- **`home.stateVersion`**：導入時の Nixpkgs リリースに合わせる（例では 26.05）。Nixpkgs と home-manager のリリースがずれると警告が出る。
- **Intel Mac（x86_64-darwin）は打ち切り方向**：NixOS 26.05 リリースノート逐語のとおり "This will be the last release of Nixpkgs to support x86_64-darwin. Platform support will be maintained and binaries built until Nixpkgs 26.05 goes out of support at the end of 2026. For 26.11... we will no longer build packages for x86_64-darwin or support building them from source."（背景は Apple の "macOS 26 will be the final version to support Intel Macs"）。M1 なら `aarch64-darwin` で問題なし。
- **Determinate インストーラの README は表記が古い**：`--prefer-upstream-nix` が残っているが 2025年11月10日以降は実質無効。Determinate を選ぶなら nix-darwin 側で `nix.enable = false;` が必須。設定しないと `error: Determinate detected, aborting activation`（nix-darwin の modules/system/checks.nix が出す逐語メッセージ："Determinate uses its own daemon to manage the Nix installation that conflicts with nix-darwin's native Nix management. To turn off nix-darwin's management of the Nix installation, set: `nix.enable = false;`"）で中断する。この opt-out 機構は nix-darwin PR #1313（master）・#1326（24.11）で追加された。
- **root 実行の副作用**：`sudo darwin-rebuild` は root で走るため、プライベートフレークや SSH 鍵を要する場合に鍵が見つからないことがある。nix-darwin Issue #1471 の逐語 "Now that darwin-rebuild requires using sudo, I am unable to access private flakes / git repos, as root does not have my ssh keys, so my system fails to build." のとおり既知の摩擦点。回避策として同 Issue で "`darwin-rebuild build --flake ~/flake.nix && sudo ./result/activate` seems to work okay"（ビルドはユーザーで、アクティベートのみ root で）が報告されている。
- **秘密情報はリポジトリに置かない**：フレークの内容は world-readable な Nix ストアにコピーされる。SSH 鍵・API トークンは別管理（sops-nix 等）。

## 一部のアプリはNixで管理しない

- Claude Code 最新版の更新が早くモデルが利用できない機能が使えない可能性があるため
  - 更新の遅れを気にしての採用のため、公式インストーラを使った運用とする
- Naya Flow は Nix でも Homebrew でも管理されていないキーボードのキーマップ変更GUIツールのため
- HHKB のキーマップ変更ツールも Nix でも Homebrew でも管理されていないGUIツールのため

### Herdr のプラグインも Nix で管理しない

- `herdr plugin install persiyanov/herdr-reviewr`: コーディングエージェントの変化点を確認しやすくするためのプラグイン
