{ ... }:
{
  # 公式（上流）インストーラで Nix を入れた場合はこのまま（既定 true）。
  # nix-darwin が /etc/nix/nix.conf を管理する。
  # ※ Determinate Nix を使う場合はここを false にすること。
  nix.enable = true;

  # flakes と nix-command を恒久的に有効化
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ストア自動最適化
  nix.optimise.automatic = true;

  # /etc/zshrc に nix-darwin 環境を読み込ませる
  programs.zsh.enable = true;
}
