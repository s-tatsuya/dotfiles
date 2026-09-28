{ pkgs, ... }:
let
  # prettier はパーサを明示しないと stdin の言語を判別できない。
  # `with pkgs` 下の pkgs.prettier を隠さないよう別名にしている。
  prettierWith = parser: {
    command = "prettier";
    args = [
      "--parser"
      parser
    ];
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
      # mpls: markdown をブラウザにライブプレビューする LSP。
      # discussions/11325 で紹介されている mdpls は開発が止まっており nixpkgs にも
      # ないので、同じ discussion で後継として挙がっている mpls を使う。
      mpls
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
      theme = "osaka_jade";

      editor = {
        line-number = "relative";
        mouse = false;
        bufferline = "multiple";
        cursor-shape.insert = "bar";
      };

      keys.normal.esc = [
        "collapse_selection"
        "keep_primary_selection"
      ];

      # markdown のプレビューをブラウザで開く（mpls の workspace command）。
      # mpls の README は C-m を例示しているが、端末では C-m = Enter なので使わない。
      keys.normal.space.m = ":lsp-workspace-command open-preview";
    };

    # ~/.config/helix/themes/osaka_jade.toml を生成する。
    # ghostty.nix の osaka-jade（omarchy のテーマ）と色を揃えるための自作テーマ。
    # 上流は Neovim 用に bamboo.nvim を流用しているだけで Helix 用の定義は無いので、
    # ターミナル側と同じ 16 色 + 背景/前景から起こしている。
    # UI 用の中間色（cursorline や overlay 系）は bg / surface1 / overlay / fg を
    # 線形補間して作った派生色で、元のパレットには無い。
    themes.osaka_jade = {
      # ── syntax ──────────────────────────────────────────────────────────────
      "attribute" = "aqua";

      "type" = "yellow";
      "type.enum.variant" = "teal_soft";

      "constructor" = "teal";

      "constant" = "mist";
      "constant.character" = "teal_soft";
      "constant.character.escape" = "pink";

      "string" = "green_bright";
      "string.regexp" = "pink";
      "string.special" = "sage";
      "string.special.symbol" = "red_soft";

      "comment" = {
        fg = "overlay";
        modifiers = [ "italic" ];
      };

      "variable" = "fg";
      "variable.parameter" = {
        fg = "mist";
        modifiers = [ "italic" ];
      };
      "variable.builtin" = "red";
      "variable.other.member" = "aqua";

      "label" = "pink";

      "punctuation" = "overlay2";
      "punctuation.special" = "teal";

      "keyword" = "pink";
      "keyword.control.conditional" = {
        fg = "pink";
        modifiers = [ "italic" ];
      };
      "keyword.directive" = "teal_soft";

      "operator" = "teal_soft";

      "function" = "teal";
      "function.macro" = "pink";

      "tag" = "sage";

      "namespace" = {
        fg = "aqua";
        modifiers = [ "italic" ];
      };

      "special" = "cursor"; # fuzzy matcher のハイライト

      # ── markup（markdown をよく書くので厚めに）──────────────────────────────
      "markup.heading.1" = "jade";
      "markup.heading.2" = "teal";
      "markup.heading.3" = "teal_soft";
      "markup.heading.4" = "green_bright";
      "markup.heading.5" = "sage";
      "markup.heading.6" = "mist";
      "markup.list" = "yellow";
      "markup.list.unchecked" = "overlay2";
      "markup.list.checked" = "green_bright";
      "markup.bold" = {
        fg = "cursor";
        modifiers = [ "bold" ];
      };
      "markup.italic" = {
        fg = "cursor";
        modifiers = [ "italic" ];
      };
      "markup.strikethrough" = {
        modifiers = [ "crossed_out" ];
      };
      "markup.link.url" = {
        fg = "sage";
        modifiers = [
          "italic"
          "underlined"
        ];
      };
      "markup.link.text" = "mist";
      "markup.link.label" = "aqua";
      "markup.raw" = "green_bright";
      "markup.quote" = "overlay2";

      "diff.plus" = "green_bright";
      "diff.minus" = "red";
      "diff.delta" = "yellow";

      # ── UI ──────────────────────────────────────────────────────────────────
      "ui.background" = {
        fg = "fg";
        bg = "bg";
      };

      "ui.linenr" = {
        fg = "overlay";
      };
      "ui.linenr.selected" = {
        fg = "cursor";
      };

      "ui.statusline" = {
        fg = "subtext";
        bg = "bg_dark";
      };
      "ui.statusline.inactive" = {
        fg = "overlay";
        bg = "bg_dark";
      };
      "ui.statusline.normal" = {
        fg = "bg";
        bg = "cursor";
        modifiers = [ "bold" ];
      };
      "ui.statusline.insert" = {
        fg = "bg";
        bg = "green_bright";
        modifiers = [ "bold" ];
      };
      "ui.statusline.select" = {
        fg = "bg";
        bg = "pink";
        modifiers = [ "bold" ];
      };

      "ui.popup" = {
        fg = "fg";
        bg = "surface";
      };
      "ui.window" = {
        fg = "surface1";
      };
      "ui.help" = {
        fg = "subtext";
        bg = "surface";
      };

      "ui.bufferline" = {
        fg = "overlay1";
        bg = "bg_dark";
      };
      "ui.bufferline.active" = {
        fg = "teal";
        bg = "bg";
        underline = {
          color = "teal";
          style = "line";
        };
      };
      "ui.bufferline.background" = {
        bg = "bg_darker";
      };

      "ui.text" = "fg";
      "ui.text.focus" = {
        fg = "white";
        bg = "surface1";
        modifiers = [ "bold" ];
      };
      "ui.text.inactive" = {
        fg = "overlay1";
      };
      "ui.text.directory" = {
        fg = "sage";
      };

      "ui.virtual" = "overlay";
      "ui.virtual.ruler" = {
        bg = "surface";
      };
      "ui.virtual.indent-guide" = "surface1";
      "ui.virtual.inlay-hint" = {
        fg = "overlay";
        bg = "bg_dark";
      };
      "ui.virtual.jump-label" = {
        fg = "cursor";
        modifiers = [ "bold" ];
      };

      "ui.selection" = {
        bg = "surface2";
      };

      "ui.cursor" = {
        fg = "bg";
        bg = "overlay2";
      };
      "ui.cursor.primary" = {
        fg = "bg";
        bg = "cursor";
      };
      "ui.cursor.match" = {
        fg = "yellow";
        modifiers = [ "bold" ];
      };
      "ui.cursor.primary.normal" = {
        fg = "bg";
        bg = "cursor";
      };
      "ui.cursor.primary.insert" = {
        fg = "bg";
        bg = "green_bright";
      };
      "ui.cursor.primary.select" = {
        fg = "bg";
        bg = "pink";
      };

      "ui.cursorline.primary" = {
        bg = "cursorline";
      };

      "ui.highlight" = {
        bg = "surface1";
        modifiers = [ "bold" ];
      };

      "ui.menu" = {
        fg = "subtext";
        bg = "surface";
      };
      "ui.menu.selected" = {
        fg = "white";
        bg = "surface2";
        modifiers = [ "bold" ];
      };

      "diagnostic.error" = {
        underline = {
          color = "red";
          style = "curl";
        };
      };
      "diagnostic.warning" = {
        underline = {
          color = "yellow";
          style = "curl";
        };
      };
      "diagnostic.info" = {
        underline = {
          color = "mist";
          style = "curl";
        };
      };
      "diagnostic.hint" = {
        underline = {
          color = "teal";
          style = "curl";
        };
      };
      "diagnostic.unnecessary" = {
        modifiers = [ "dim" ];
      };

      error = "red";
      warning = "yellow";
      info = "mist";
      hint = "teal";

      # ── palette ─────────────────────────────────────────────────────────────
      palette = {
        # ghostty の background / foreground / cursor-color
        bg = "#111c18";
        fg = "#C1C497";
        cursor = "#D7C995";

        # ANSI 0/8 と、そこから作った UI 用の派生色
        bg_darker = "#0b1210"; # bufferline の余白
        bg_dark = "#0e1714"; # statusline
        cursorline = "#192821";
        surface = "#1e2f25"; # popup / menu
        surface1 = "#23372B"; # ANSI 0
        surface2 = "#364b3e"; # selection
        overlay = "#53685B"; # ANSI 8。コメントと行番号
        overlay1 = "#72826c";
        overlay2 = "#8a9679";
        subtext = "#a6ad88";

        # ANSI 1..15
        red = "#FF5345"; # 1
        green = "#549e6a"; # 2
        moss = "#459451"; # 3
        sage = "#509475"; # 4
        pink = "#D2689C"; # 5
        teal = "#2DD5B7"; # 6
        white = "#F6F5DD"; # 7
        red_soft = "#db9f9c"; # 9
        green_bright = "#63b07a"; # 10
        yellow = "#E5C736"; # 11
        mist = "#ACD4CF"; # 12
        aqua = "#75bbb3"; # 13
        teal_soft = "#8CD3CB"; # 14
        jade = "#9eebb3"; # 15
      };
    };

    # ~/.config/helix/languages.toml を生成する。
    languages = {
      language-server = {
        # markdown のライブプレビュー用 LSP。テーマは editor 側の osaka_jade に
        # 寄せる。`mpls --list-themes` に osaka-jade は無いので、同系統の暗い緑
        # である everforest-dark を代わりに使う。--no-auto を付けないとファイルを
        # 開いた時点でブラウザが立ち上がるので、space+m で明示的に開く運用にする。
        mpls = {
          command = "mpls";
          args = [
            "--theme"
            "everforest-dark"
            "--no-auto"
          ]
          # macOS では `open -a <browser>` に渡されるのでアプリ名で指定する。
          # Linux では xdg-open（既定のブラウザ）に任せる。
          ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
            "--browser"
            "Safari"
          ];
        };
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
          language-servers = [
            "marksman"
            "mpls"
          ];
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
            args = [
              "fmt"
              "-"
            ];
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
          language-servers = [
            "pyright"
            "ruff"
          ];
          formatter = {
            command = "ruff";
            args = [
              "format"
              "-"
            ];
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
