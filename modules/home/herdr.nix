{ config, ... }:
{
  # herdr（本体は packages.nix で flake input から入れている）の設定。
  #
  # herdr は画面からテーマを変えたときなどに config.toml を自分で書き換える
  # （std::fs::write で中身を上書きするので symlink はたどられる）。Nix ストアへの
  # 読み取り専用 symlink だと書き込みに失敗するので、repo の実ファイルへの
  # 書き込み可能な symlink にする（mkOutOfStoreSymlink、karabiner.nix と同じ考え方）。
  #
  # ~/.config/herdr/ にはソケット・ログ・セッションも置かれるので、ディレクトリごとではなく
  # config.toml だけをリンクにする。
  #
  # 初回だけ、既存の ~/.config/herdr/config.toml（実ファイル）をどかしてから switch すること。
  # 反映は `herdr server reload-config`（サーバーを止めずに読み直す）。
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/modules/home/herdr/config.toml";
}
