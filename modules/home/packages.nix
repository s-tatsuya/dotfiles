{ pkgs, inputs, ... }:
let
  # explex-nf v0.0.3 は macOS で斜体の m が消える（yuru7/Explex#1、upstream 未修正）。
  # 原因は BoldItalic の 2 つの不具合で、Wave（Chromium）のテストで確認した:
  #   - m 系グリフに 2 点だけの退化した輪郭があり、CoreText がグリフごと描かない
  #   - BoldItalic の weight が 400 のままで、ただの斜体（\e[3m）にも BoldItalic が選ばれる
  # fontTools で両方を直したコピーを作って入れる。詳細は fonts/fix-explex.py。
  explex-nf = pkgs.runCommand "explex-nf-fixed-${pkgs.explex-nf.version}" {
    nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.fonttools ])) ];
  } ''
    cp -r ${pkgs.explex-nf} $out
    chmod -R u+w $out
    python3 ${./fonts/fix-explex.py} $out/share/fonts/truetype/*/*.ttf
  '';
in
{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    tree

    # Explex（0xProto + IBM Plex Sans JP）の Nerd Fonts 合成版。
    # 手動ダウンロードせず nixpkgs のパッケージで入れる。upstream の
    # yuru7/Explex v0.0.3 の Explex_NF zip 相当。
    # nixpkgs が収録しているのは Console 版だけで、これは罫線記号（U+2500-257F）を
    # 半角のままにしたバリアント。非 Console 版は罫線が全角になり TUI の枠が崩れるので、
    # ターミナル用途ではこちらが正しい。
    # 参照側は modules/home/ghostty.nix の font-family。フォントはアプリ横断の
    # リソースなので、特定アプリのモジュールではなくここに置く。
    # 実体は上の let で macOS の斜体の不具合を直したもの。
    explex-nf
  ] ++ [
    # nixpkgs にないので flake input から。system は評価するホストごとに解決されるので Linux でもそのまま動く
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # home.packages に入れたフォントを OS から見えるようにする経路はプラットフォームで別物。
  #
  # macOS: home-manager の targets/darwin/fonts.nix が share/fonts を
  #   ~/Library/Fonts/HomeManager/ へ rsync する（symlink ではなく実体コピー。macOS は
  #   symlink のフォントを認識しないため）。探索は CoreText なので fontconfig は不要で、
  #   有効にすると profile に fc-cache 用のダミー derivation が増えるだけなので入れない。
  #
  # Linux: fontconfig 経由。ただし fonts.fontconfig.enable の default は
  #   「NixOS の submodule として動いていて useUserPackages が有効」なときだけ true になる。
  #   standalone home-manager（Ubuntu など）では false のままなので、明示的に有効化しないと
  #   home.packages のフォントが見つからない。
  fonts.fontconfig.enable = pkgs.stdenv.hostPlatform.isLinux;
}
