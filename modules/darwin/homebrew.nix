{ config, ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";   # 設定にないものは削除(Nixっぽく宣言的に保つ)
    };

    # taps の実体は nix-homebrew が管理する。ただし brew bundle に tap 名を渡さないと
    # cleanup が「Brewfile にない tap」とみなして untap しようとし、インストール済み cask
    # があるため "Refusing to untap homebrew/cask" で失敗する。nix-homebrew 側の定義から渡す。
    taps = builtins.attrNames config.nix-homebrew.taps;

    casks = [
      # ターミナル。nixpkgs の ghostty は Linux 専用なので cask で入れる。
      # 設定は modules/home/ghostty.nix が ~/.config/ghostty/config を生成する。
      "ghostty"
      "scroll-reverser"
      "karabiner-elements"
      "claude"
      "visual-studio-code"
    ];

    # Mac App Store 製アプリを入れたい場合(任意):
    # masApps = {
    #   "Xcode" = 497799835;
    # };
  };
}
