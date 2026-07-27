{ pkgs, username, ... }:
{
  imports = [
    ../modules/home
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # 初回導入時のバージョン。基本的に変更しない。
  home.stateVersion = "26.05";

  # home-manager 自身を管理（CLI も利用可能になる）
  programs.home-manager.enable = true;
}
