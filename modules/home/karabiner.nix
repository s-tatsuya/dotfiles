{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Karabiner-Elements（本体は modules/darwin/homebrew.nix の cask）の設定。
  #
  # Karabiner は GUI で設定を変えるたびに karabiner.json を自分で書き換える（一時ファイルに
  # 書いて rename する）ので、Nix ストアへの読み取り専用 symlink にはできない。
  # そこで ~/.config/karabiner をディレクトリごと repo の modules/home/karabiner/ への
  # 書き込み可能な symlink にする（mkOutOfStoreSymlink）。ディレクトリ単位の symlink は
  # Karabiner の公式ドキュメントが案内している方法で、ファイル単位だと保存時に実ファイルへ
  # 置き換えられてしまう。GUI での変更はそのまま repo の差分として現れる。
  #
  # 中身:
  #   - IME 用の英数/かな（無変換/変換キー）
  #   - HHKB（vendor_id 1278 = PFU）だけ左 Command と左 Option を入れ替え
  #   - Wave の中だけで効くブロック操作（Ctrl+Shift+Z で最大化、Ctrl+Shift+X で閉じる。
  #     herdr の prefix+z / x に合わせた）
  #
  # 初回だけ、既存の ~/.config/karabiner（実ディレクトリ）をどかしてから switch すること。
  # home-manager は管理外のファイルを上書きしないので、残っていると switch が止まる。
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    xdg.configFile."karabiner".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/modules/home/karabiner";
  };
}
