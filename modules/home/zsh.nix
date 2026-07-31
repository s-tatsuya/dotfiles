{ pkgs, ... }:
{
  # nix-darwin 側でも zsh を有効化しているが、home-manager 側でも
  # 有効化すると direnv などのフックが確実に挿入される。
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # ~/.zshrc に `alias <name>='<value>'` として展開される。
    # 値は zsh の文字列としてそのまま渡るので、クォートは Nix 側で意識しない。
    shellAliases = {
      # このリポジトリの適用・確認
      # 末尾スペースがないと `drs` のような別名を続けて書いたとき展開されないが、
      # ここは単独で使う想定なので不要。
      claude = "claude --permission-mode auto";
    };

    # Plugin 関連の設定を追加
    plugins = [
      {
        # サブコンマンドの自動補完
        name = "zsh-completions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-completions";
          rev = "0.35.0";
          sha256 = "sha256-GFHlZjIHUWwyeVoCpszgn4AmLPSSE8UVNfRmisnhkpg=";
        };
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "shre/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
