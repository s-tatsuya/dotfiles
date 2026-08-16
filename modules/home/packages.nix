{ pkgs, inputs, ... }:
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
