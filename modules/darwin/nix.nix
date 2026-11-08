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

  # 古い世代とどこからも参照されないパッケージを自動で掃除する（launchd で週 1 回、
  # 既定は日曜 3:15）。optimise は重複の整理だけで消しはしないので、こちらが無いと
  # 試しに入れたパッケージや古い世代が /nix/store に溜まり続ける。
  # 30 日より新しい世代は残るので、直近の変更は darwin-rebuild --rollback で戻せる。
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  # /etc/zshrc に nix-darwin 環境を読み込ませる
  programs.zsh.enable = true;
}
