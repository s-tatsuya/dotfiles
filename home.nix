{ pkgs, ... }:
let
  # 環境変数から取得。取れない場合はデフォルト（例: "tatsuya"）を使う設定
  user = builtins.getEnv "USER";
  actualUser = if user == "" then "tatsuya" else user;
  homePrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
in {
  home.username = actualUser;
  home.homeDirectory = "${homePrefix}/${actualUser}";

  home.stateVersion = "24.11";# Home Manager自身を有効にする
  programs.home-manager.enable = true;

  home.file = {

    # fishはまずは、ディレクトリごとではなく、必要なファイル・フォルダだけを個別に指定
    ".config/fish/config.fish".source = ./config/fish/config.fish;
    ".config/fish/tide_settings.fish".source = ./config/fish/tide_settings.fish;
    ".config/fish/conf.d".source = ./config/fish/conf.d;
    ".config/fish/functions".source = ./config/fish/functions;
    ".config/fish/fish_plugins".source = ./config/fish/fish_plugins;

    ".config/zellij/config.kdl".source = if pkgs.stdenv.isDarwin
      then ./config/zellij/config-mac.kdl
      else ./config/zellij/config.kdl;
    ".config/nvim".source = ./config/nvim;
    ".config/alacritty".source = ./config/alacritty;
  };

  programs.neovim = {
    enable = true;
    extraLuaPackages = ps: [ ps.magick ];
  };

  home.packages = with pkgs; [
    fish
    zellij
    docker
    docker-compose
    ripgrep
    github-copilot-cli
    imagemagick
    plantuml
    mermaid-cli
  ];

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    '';
    # Bashがインタラクティブモードで起動した時に実行するコマンド
    initExtra = ''
      if [[ $- == *i* && -x ${pkgs.fish}/bin/fish ]]; then
        exec ${pkgs.fish}/bin/fish
      fi
    '';
  };

  programs.git = {
    enable = true;

    # 新しい書き方: すべて settings の中に構造化して書く
    settings = {
      user = {
        name = "Tatsuya Sakurai";
        email = "s.tatsuya0123@gmail.com";
      };
      core = {
        editor = "nvim";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = true;
      };
      merge = {
        ff = false;
      };
      diff = {
        tool = "vscode";
      };
      difftool = {
        vscode = {
          cmd = "code --wait --diff $LOCAL $REMOTE";
        };
      };
      # エイリアスが必要な場合はここ
      alias = {
        # st = "status";
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # Nix との連携を強化
    # Fish への統合は Home Manager が自動で行います
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true; # Ctrl+r 等を有効化
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
    };
  };
}
