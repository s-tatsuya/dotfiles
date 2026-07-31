{ ... }:
{
  # nix-darwin 側でも zsh を有効化しているが、home-manager 側でも
  # 有効化すると direnv などのフックが確実に挿入される。
  programs.zsh = {
    enable = true;

    # ~/.zshrc に `alias <name>='<value>'` として展開される。
    # 値は zsh の文字列としてそのまま渡るので、クォートは Nix 側で意識しない。
    shellAliases = {
      # このリポジトリの適用・確認
      # 末尾スペースがないと `drs` のような別名を続けて書いたとき展開されないが、
      # ここは単独で使う想定なので不要。
      claude = "claude --permission-mode auto";
    };
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
