{ ... }:
{
  programs.ghostty = {
    enable = true;

    # nixpkgs の ghostty は meta.platforms が *-linux だけなので aarch64-darwin では
    # 評価に失敗する。macOS では本体を Homebrew cask（modules/darwin/homebrew.nix）で入れ、
    # ここでは設定ファイルの生成だけを担当する。
    # package = null はモジュール側が「ghostty が使えないプラットフォーム向け」として
    # 用意している指定で、home.packages への追加をスキップする。
    package = null;

    # Ghostty が渡す $GHOSTTY_RESOURCES_DIR がある場合だけ shell integration を読み込む。
    # 本体が Homebrew 由来でも環境変数は Ghostty 側が設定するので機能する。
    enableZshIntegration = true;

    # ~/.config/ghostty/config を生成する。macOS の Ghostty も XDG のパスを読む。
    settings = {
      # 名前は `ghostty +list-themes` の表記どおり。helix の tokyonight_storm に合わせている。
      theme = "TokyoNight Storm";

      font-size = 14;
      window-padding-x = 8;
      window-padding-y = 8;
      mouse-hide-while-typing = true;
    };
  };
}
