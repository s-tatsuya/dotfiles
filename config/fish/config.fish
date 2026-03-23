if status is-interactive
    # -----------------------------------------------------
    # tide(Fish用のプロンプトテーマ）設定
    # -----------------------------------------------------
    if test -f ~/.config/fish/tide_settings.fish
        source ~/.config/fish/tide_settings.fish
    end
    # Commands to run in interactive sessions can go here
    # -----------------------------------------------------
    # SSHの初回入力
    # -----------------------------------------------------
    # ssh-agentが起動していなければ起動する
    if not set -q SSH_AUTH_SOCK
        eval (ssh-agent -c)
        set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
        set -Ux SSH_AGENT_PID $SSH_AGENT_PID
    end

    # 鍵をエージェントに追加（まだ追加されていない場合のみ）
    if not ssh-add -l 2>/dev/null | string match -q "*id_ed25519*"
        ssh-add ~/.ssh/id_ed25519
    end
    # -----------------------------------------------------
    # エイリアスの設定
    # -----------------------------------------------------
    # -----------------------------------------------------
    # 環境変数の設定
    # -----------------------------------------------------
    if test -f ~/.config/fish/environment.fish
        source ~/.config/fish/environment.fish
    end
    # -----------------------------------------------------
    # fzf.fishの設定
    # -----------------------------------------------------
    fzf_configure_bindings --directory=\ct --git_log=\cw --git_status=\ce --processes=\cy --variables=
    # -----------------------------------------------------
    # Zellijの設定
    # -----------------------------------------------------
    if status is-interactive
    # 1. すでにZellijの中にいないこと
    # 2. かつ、VSCodeのターミナルではないこと
        if not set -q ZELLIJ; and test "$TERM_PROGRAM" != "vscode"
            exec zellij
        end
    end
    # -----------------------------------------------------
    # uvの設定
    # Pythonの仮想環境とパッケージの管理ツール
    # -----------------------------------------------------
    # uvの補完設定 (Fish用に出力を変更)
    if command -q uv
        uv generate-shell-completion fish | source
    end
    if command -q uvx
        uvx --generate-shell-completion fish | source
    end

    # PATHの追加 (fish_add_pathを使うと重複を防げます)
    fish_add_path "$HOME/.local/bin"



    # -----------------------------------------------------
    # pnpmの設定
    # JavaScriptのパッケージマネージャー
    # -----------------------------------------------------
    set -gx PNPM_HOME "/Users/sakuraitatsuya/Library/pnpm"
    if not contains "$PNPM_HOME" $PATH
        set -gx PATH "$PNPM_HOME" $PATH
    end

    # -----------------------------------------------------
    # Nodeの設定
    # -----------------------------------------------------
    # nvmの設定 (fish-nvm などのプラグイン利用を推奨しますが、基本設定は以下の通り)
    set -gx NVM_DIR "$HOME/.nvm"
    # 注: nvm.shはBash専用です。Fishでnvmを使うには "nvm-fish" 等のプラグインを入れるのが一般的です。


    # -----------------------------------------------------
    # Cargoの設定（Rust）
    # -----------------------------------------------------
    if test -f "$HOME/.cargo/env.fish"
        source "$HOME/.cargo/env.fish"
    else if test -f "$HOME/.cargo/env"
        # .envがBash形式の場合、直接sourceするとエラーになることがあります
        # その場合はPATHを手動で通します
        fish_add_path "$HOME/.cargo/bin"
    end
end
