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
  #   - Keychron K11 Max（vendor_id 13364）を ignore = false で変更対象にする。キーボードと
  #     マウスを兼ねる機器として見えるため、既定では Karabiner の対象外になり、上記のルールが効かない
  #   - Wave の中だけで効くブロック操作（Ctrl+Shift+Z で最大化、Ctrl+Shift+X で閉じる。
  #     herdr の prefix+z / x に合わせた）
  #
  # 初回だけ、既存の ~/.config/karabiner（実ディレクトリ）をどかしてから switch すること。
  # home-manager は管理外のファイルを上書きしないので、残っていると switch が止まる。
  # switch 後は Karabiner を再起動すること（設定画面の Quit, Restart → Restart、または
  # `launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.Karabiner-Core-Service-rev2`）。
  # Karabiner は起動時に設定ディレクトリの実体を見張り始めるので、起動中に symlink へ
  # 差し替えると、repo 側の変更（GUI での変更も含む）を読み直さなくなる。
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    xdg.configFile."karabiner".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/modules/home/karabiner";
  };
}
