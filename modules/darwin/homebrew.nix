{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";   # 設定にないものは削除(Nixっぽく宣言的に保つ)
    };

    taps = [];   # taps は nix-homebrew 側で管理するのでここは空でOK

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
