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
        # 補完候補を fzf で選ぶ。compinit の後に読み込まれる必要があるが、
        # home-manager は plugins を compinit の後に source するので条件を満たす。
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
  };

  # サブコマンドの自動補完。
  # plugins で入れると補完関数のあるディレクトリが fpath に入るのが
  # compinit より後になって効かないため、パッケージとして入れる。
  # nix パッケージは share/zsh/site-functions に置かれ、こちらは
  # home-manager が compinit より前に fpath へ追加してくれる。
  home.packages = [ pkgs.zsh-completions ];

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
