{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # /nix が別ボリュームにあるためコールドスタート時に git の起動が
      # デフォルトの 500ms を超えることがある
      command_timeout = 1000;
    };
  };
}
