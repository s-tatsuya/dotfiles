{ ... }:
{
  # nix-darwin 側でも zsh を有効化しているが、home-manager 側でも
  # 有効化すると direnv などのフックが確実に挿入される。
  programs.zsh.enable = true;

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
