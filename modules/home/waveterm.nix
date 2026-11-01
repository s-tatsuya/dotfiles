{ lib, ... }:
let
  # ghostty.nix / helix.nix の osaka-jade と同じ色。
  # 元ネタは omarchy の osaka-jade テーマ（https://github.com/Justikun/omarchy-osaka-jade-theme）。
  bg = "#111c18";
  fg = "#C1C497";
  cursor = "#D7C995";
  surface = "#23372B"; # ANSI 0
  overlay = "#53685B"; # ANSI 8
  sage = "#509475"; # ANSI 4
in
{
  # Wave Terminal の設定（~/.config/waveterm/*.json）。
  #
  # 本体は Homebrew cask（modules/darwin/homebrew.nix）で入れるので package = null で
  # 設定生成だけを担当する（ghostty.nix と同じ形）。
  #
  # 注意: 生成物は Nix ストアへの読み取り専用 symlink になるので、Wave の設定画面や
  # `wsh setconfig` で settings.json を書き換えることはできなくなる。設定はここで変える。
  programs.waveterm = {
    enable = true;
    package = null;

    settings = {
      # もともと手元の settings.json にあった値を引き継ぐ。
      "autoupdate:channel" = "latest";

      # 下の themes で定義した端末テーマ。
      "term:theme" = "osaka-jade";

      # ウィンドウ全体の地の色（タブバーやブロックの隙間に見える部分）。
      # Wave は CSS 変数 --main-bg-color をこれで上書きする。
      "window:bgcolor" = bg;
    };

    # ~/.config/waveterm/termthemes.json。キー名は xterm.js の ITheme に
    # Wave 独自の gray / cmdtext を足したもの。
    themes.osaka-jade = {
      "display:name" = "Osaka Jade";
      "display:order" = 1;

      black = surface;
      red = "#FF5345";
      green = "#549e6a";
      yellow = "#459451";
      blue = sage;
      magenta = "#D2689C";
      cyan = "#2DD5B7";
      white = "#F6F5DD";

      brightBlack = overlay;
      brightRed = "#db9f9c";
      brightGreen = "#63b07a";
      brightYellow = "#E5C736";
      brightBlue = "#ACD4CF";
      brightMagenta = "#75bbb3";
      brightCyan = "#8CD3CB";
      brightWhite = "#9eebb3";

      gray = overlay;
      cmdtext = fg;
      foreground = fg;
      background = bg;
      cursor = cursor;
      cursorAccent = "#000000";
      selectionBackground = "${surface}cc";
    };
  };

  # ~/.config/waveterm/backgrounds.json。ブロックの枠線色とタブの背景をまとめた
  # 「タブの背景」プリセット。home-manager の programs.waveterm には対応する
  # オプションが無いので直接置く。
  #
  # Wave はこれをタブ単位のメタデータ（tab:background）として持つため、全タブに
  # 一括で効かせる設定は無い。タブを右クリック → Backgrounds → Osaka Jade で選ぶか、
  # そのタブの端末で `wsh setmeta -b tab tab:background=bg@osaka-jade` を叩く。
  xdg.configFile."waveterm/backgrounds.json".text = lib.generators.toJSON { } {
    "bg@osaka-jade" = {
      "display:name" = "Osaka Jade";
      "display:order" = 1;
      bg = bg;
      "bg:bordercolor" = surface;
      "bg:activebordercolor" = sage;
    };
  };
}
