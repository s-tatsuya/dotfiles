{ pkgs, ... }:
let
  # prettier はパーサを明示しないと stdin の言語を判別できない。
  # `with pkgs` 下の pkgs.prettier を隠さないよう別名にしている。
  prettierWith = parser: {
    command = "prettier";
    args = [ "--parser" parser ];
  };
in
{
  programs.helix = {
    enable = true;

    # $EDITOR / $VISUAL を hx にする。git の core.editor は git.nix 側で設定。
    defaultEditor = true;

    # LSP・フォーマッタは hx のラッパー内の PATH にだけ通す。
    # home.packages と違ってグローバルな PATH は汚さない。
    extraPackages = with pkgs; [
      # Nix
      nil
      nixfmt-rfc-style
      # Markdown / YAML / TOML
      marksman
      yaml-language-server
      taplo
      # TypeScript / JavaScript（vscode-langservers-extracted は HTML/CSS/JSON/ESLint）
      typescript-language-server
      vscode-langservers-extracted
      prettier
      # Python
      pyright
      ruff
      # Rust
      rust-analyzer
      rustfmt
    ];

    # ~/.config/helix/config.toml を生成する。
    settings = {
      theme = "tokyonight_storm";

      editor = {
        line-number = "relative";
        mouse = false;
        bufferline = "multiple";
        cursor-shape.insert = "bar";
      };

      keys.normal.esc = [ "collapse_selection" "keep_primary_selection" ];
    };

    # ~/.config/helix/languages.toml を生成する。
    languages = {
      language-server = {
        # helix 同梱の定義は pylsp が既定なので明示的に上書きする。
        pyright = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
        };
        ruff = {
          command = "ruff";
          args = [ "server" ];
        };
      };

      language = [
        {
          name = "nix";
          language-servers = [ "nil" ];
          formatter.command = "nixfmt";
          auto-format = true;
        }
        {
          name = "markdown";
          language-servers = [ "marksman" ];
          formatter = prettierWith "markdown";
          auto-format = true;
        }
        {
          name = "yaml";
          language-servers = [ "yaml-language-server" ];
          formatter = prettierWith "yaml";
          auto-format = true;
        }
        {
          name = "toml";
          language-servers = [ "taplo" ];
          formatter = {
            command = "taplo";
            args = [ "fmt" "-" ];
          };
          auto-format = true;
        }
        {
          name = "json";
          language-servers = [ "vscode-json-language-server" ];
          formatter = prettierWith "json";
          auto-format = true;
        }
        {
          name = "typescript";
          language-servers = [ "typescript-language-server" ];
          formatter = prettierWith "typescript";
          auto-format = true;
        }
        {
          name = "tsx";
          language-servers = [ "typescript-language-server" ];
          formatter = prettierWith "typescript";
          auto-format = true;
        }
        {
          name = "javascript";
          language-servers = [ "typescript-language-server" ];
          formatter = prettierWith "babel";
          auto-format = true;
        }
        {
          name = "jsx";
          language-servers = [ "typescript-language-server" ];
          formatter = prettierWith "babel";
          auto-format = true;
        }
        {
          name = "python";
          language-servers = [ "pyright" "ruff" ];
          formatter = {
            command = "ruff";
            args = [ "format" "-" ];
          };
          auto-format = true;
        }
        {
          name = "rust";
          language-servers = [ "rust-analyzer" ];
          formatter.command = "rustfmt";
          auto-format = true;
        }
      ];
    };
  };
}
