{ pkgs, username, ... }:
{
  imports = [
    ../../modules/darwin
  ];

  # sudo / Touch ID / homebrew などが適用される主ユーザー
  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Apple Silicon
  nixpkgs.hostPlatform = "aarch64-darwin";

  # 後方互換用。`darwin-rebuild changelog` を参照。
  # `nix flake init -t nix-darwin` が生成する現行値を使うのが安全。
  system.stateVersion = 6;
}
