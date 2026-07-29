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
      "scroll-reverser"
      "karabiner-elements"
    ];

    # Mac App Store 製アプリを入れたい場合(任意):
    # masApps = {
    #   "Xcode" = 497799835;
    # };
  };
}
