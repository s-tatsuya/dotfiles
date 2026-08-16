{ lib, pkgs, ... }:
{
  programs.ghostty = {
    enable = true;

    # macOS では nixpkgs の ghostty が meta.platforms = *-linux のため評価に失敗する。
    # 本体は Homebrew cask（modules/darwin/homebrew.nix）で入れ、ここは設定生成だけを担当する。
    # package = null はモジュール側が「ghostty が使えないプラットフォーム向け」として
    # 用意している指定で、home.packages への追加をスキップする。
    #
    # Linux では逆に null にしてはいけない。programs.ghostty.systemd.enable が
    # Linux で default true になり、モジュール内の
    # `systemd.enable -> package != null` アサーションに引っかかって評価が落ちる。
    # mkIf を false 側に倒すと option の default（pkgs.ghostty）がそのまま使われる。
    package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;

    # Ghostty が渡す $GHOSTTY_RESOURCES_DIR がある場合だけ shell integration を読み込む。
    # 本体が Homebrew 由来でも環境変数は Ghostty 側が設定するので機能する。
    enableZshIntegration = true;

    # ~/.config/ghostty/config を生成する。macOS の Ghostty も XDG のパスを読む。
    settings = {
      # 名前は `ghostty +list-themes` の表記どおり。helix の tokyonight_storm に合わせている。
      theme = "TokyoNight Storm";

      # フォント本体（explex-nf）は modules/home/packages.nix で入れている。
      # 名前は `ghostty +list-fonts` の表記どおり。Bold / Italic は同じファミリ内から
      # Ghostty が自動で選ぶので font-family-bold などの明示は不要。
      # 全角と半角の比が 1:2 の標準バリアント。英数字に余裕を持たせた 3:5 比の
      # `Explex35 Console NF` も同じパッケージに入っているので、そちらも選べる。
      font-family = "Explex Console NF";

      font-size = 14;
      window-padding-x = 8;
      window-padding-y = 8;
      mouse-hide-while-typing = true;
    };
  };
}
