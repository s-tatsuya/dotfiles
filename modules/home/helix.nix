{ config, pkgs, ... }:
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

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # codebook のプロジェクト辞書を、ルート直下ではなく Helix のプロジェクト設定
  # ディレクトリ .helix/ に置けるようにする（.helix/languages.toml と同じ場所）。
  # 上流はファイル名を codebook.toml / .codebook.toml に決め打ちしていて場所を変える
  # 設定が無いので、探す候補の先頭に .helix/codebook.toml を足す。候補の先頭は
  # 「辞書がまだ無いとき Add to dictionary で作る場所」も兼ねる。既存の codebook.toml /
  # .codebook.toml もこれまでどおり読む。上流は保存時に親ディレクトリを作らないので、
  # .helix/ が無くても保存できるよう create_dir_all を足す。
  codebook = pkgs.codebook.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace crates/codebook-config/src/lib.rs \
        --replace-fail \
          'static USER_CONFIG_FILES: [&str; 2] = ["codebook.toml", ".codebook.toml"];' \
          'static USER_CONFIG_FILES: [&str; 3] = [".helix/codebook.toml", "codebook.toml", ".codebook.toml"];' \
        --replace-fail \
          '        fs::write(&project_config_path, content)' \
          '        if let Some(parent) = project_config_path.parent() { fs::create_dir_all(parent)?; }
              fs::write(&project_config_path, content)'
    '';
  });

  # 今いる Wave ブロックに向けて wsh を実行するラッパー（理由は wsh-here.nix）。
  wshHere = import ./wsh-here.nix { inherit pkgs; };

  # スペル・文法チェック用の LSP（下の language-server.codebook / harper-ls）。
  # codebook はスペル担当で、tree-sitter で変数名（camelCase を分割）・コメント・文字列を
  # 見る。harper は英語の文法担当で、markdown の本文とコードのコメントを見る。
  # どちらも日本語の部分は無視し、日本語の文中の英単語だけをチェックする。
  # harper は対応しない言語では何もしないので、prose はスペルだけ（codebook のみ）に付ける。
  spellServers = [
    "codebook"
    "harper-ls"
  ];

  # クリップボードの画像を、編集中のファイルと同じ階層の images/ に JPEG で保存し、
  # markdown の画像リンクを stdout に出す。space+i から :insert-output で呼ぶので、
  # stdout がそのままカーソル位置に挿入される（末尾に改行を付けないこと）。
  # 失敗時は非 0 で抜ければ helix が stderr を表示し、何も挿入しない。
  pasteImage = pkgs.writeShellApplication {
    name = "hx-paste-image";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        imagemagick
      ]
      # クリップボードから画像を取り出す手段は OS で別物。
      #   macOS : pngpaste（NSPasteboard の画像を PNG に変換して出す）
      #   Ubuntu: Wayland なら wl-paste、X11 なら xclip
      ++ (
        if isDarwin then
          [ pngpaste ]
        else
          [
            wl-clipboard
            xclip
          ]
      );
    text = ''
      buffer="''${1:-}"
      if [ -z "$buffer" ] || [ "$buffer" = "[scratch]" ]; then
        echo "ファイルを保存してから実行してください" >&2
        exit 1
      fi

      dir="$(dirname -- "$buffer")/images"
      name="$(date +%Y%m%d-%H%M%S)"
      # 同じ秒に 2 回貼った場合に上書きしないよう連番を付ける。
      file="$name.jpg"
      i=1
      while [ -e "$dir/$file" ]; do
        file="$name-$i.jpg"
        i=$((i + 1))
      done

      tmp="$(mktemp)"
      trap 'rm -f "$tmp"' EXIT

      ${
        if isDarwin then
          ''
            if ! pngpaste - >"$tmp" 2>/dev/null; then
              echo "クリップボードに画像がありません" >&2
              exit 1
            fi
          ''
        else
          ''
            # クリップボードの型は貼り元次第（image/png とは限らない）なので、
            # 提供されている image/* の先頭を取る。ImageMagick 側は中身から形式を判別する。
            if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
              type="$(wl-paste --list-types 2>/dev/null | grep -m1 '^image/' || true)"
              [ -n "$type" ] && wl-paste --type "$type" >"$tmp"
            else
              type="$(xclip -selection clipboard -t TARGETS -o 2>/dev/null | grep -m1 '^image/' || true)"
              [ -n "$type" ] && xclip -selection clipboard -t "$type" -o >"$tmp"
            fi
            if [ -z "$type" ]; then
              echo "クリップボードに画像がありません" >&2
              exit 1
            fi
          ''
      }

      mkdir -p -- "$dir"
      # JPEG は透過を持てないので、スクリーンショットの透明部分は白で埋める。
      magick "$tmp" -background white -alpha remove -alpha off -quality 90 "$dir/$file"

      printf '![](./images/%s)' "$file"
    '';
  };

  # mpls のプレビューを、Wave Terminal の中で hx を動かしているときは Wave の
  # web ブロックで開き、それ以外（Ghostty など）では従来どおりブラウザで開く。
  #
  # mpls 自身にはその切り替え手段が無い。macOS では `open -g -a <browser> <url>` を
  # 固定で叩き、--browser はアプリ名として -a に渡されるだけ
  # （internal/previewserver の Openbrowser）。Linux では --browser の値を
  # そのままコマンドとして `<browser> <url>` で実行する。
  #
  # 判定は WAVETERM_JWT の有無で行う。Wave の端末が子プロセスに渡す認証トークンで、
  # wsh はこれを使って Wave 本体に繋ぐので、あれば `wsh web open` が今のタブに
  # web ブロックを足せる。hx → mpls → このスクリプトと環境変数はそのまま継承される。
  mplsOpen = pkgs.writeShellScript "mpls-open" ''
    url="''${!#}" # どちらの OS でも最後の引数が URL

    if [ -n "''${WAVETERM_JWT:-}" ]; then
      # 宛先のブロックは wsh-here が今の Wave ブロックに合わせる（herdr 越しでも）。
      if out="$(${wshHere}/bin/wsh-here web open "$url" 2>&1)"; then
        # hx を閉じたらプレビューも閉じる。このスクリプトは mpls の子として起動されるので
        # $PPID が mpls。hx を閉じると mpls も終わるので、それを待って作ったブロックを消す。
        # 見張りは裏で動かし、mpls をこのスクリプトの終了待ちで止めない。
        # 先に手で閉じていた場合は deleteblock が失敗するだけで害はない。
        block="$(printf '%s\n' "$out" | sed -n 's/^created block block:\(.*\)$/\1/p')"
        if [ -n "$block" ]; then
          mpls_pid=$PPID
          (
            while kill -0 "$mpls_pid" 2>/dev/null; do sleep 2; done
            ${wshHere}/bin/wsh-here deleteblock -b "$block"
          ) </dev/null >/dev/null 2>&1 &
        fi
        exit 0
      fi
    fi

    ${
      if isDarwin then
        # mpls が組み立てた引数（-g -a Safari <url>）を本物の open にそのまま渡す。
        ''exec /usr/bin/open "$@"''
      else
        ''exec ${pkgs.xdg-utils}/bin/xdg-open "$url"''
    }
  '';

  # カーソル位置の URL を開く（space+o）。Wave の中なら web ブロック、外なら既定のブラウザ。
  #
  # hx 標準の gf も URL を開けるが、open クレート経由で /usr/bin/open を絶対パスで
  # 呼ぶため、mpls のように PATH の差し替えでは Wave に向けられない。なので別キーにする。
  #
  # :pipe-to で呼ぶので stdin は選択範囲。選択に URL が含まれていればそれを開く
  # （未保存のバッファでも URL を選択すれば開ける）。カーソルだけ（1 文字）のときは
  # 保存済みファイルのカーソル行を読み、カーソル列にかかる URL、無ければ行の先頭の URL を開く。
  openUrl = pkgs.writeShellApplication {
    name = "hx-open-url";
    runtimeInputs = [ pkgs.perl ];
    text = ''
      buffer="''${1:-}"
      line="''${2:-1}"
      col="''${3:-1}"

      # 行（または選択範囲）から URL を拾う。$col は 1 始まりの文字位置で、0 なら列を見ない。
      # 末尾の句読点や markdown の閉じ括弧は URL に含めない。
      pick() {
        perl -CSD -e '
          my $col = shift;
          local $/; my $s = <STDIN>;
          my ($first, $hit);
          while ($s =~ m{(https?://[^\s<>"`'"'"')\]]+)}g) {
            my ($u, $e) = ($1, pos($s));
            my $b = $e - length($u);
            $u =~ s/[.,;:!?]+$//;
            $first //= $u;
            if ($col > 0 && $b < $col && $col <= $e + 1) { $hit = $u; last }
          }
          print $hit // $first // "";
        ' "$1"
      }

      url="$(pick 0)"
      if [ -z "$url" ] && [ -f "$buffer" ]; then
        url="$(sed -n "''${line}p" "$buffer" | pick "$col")"
      fi
      if [ -z "$url" ]; then
        echo "URL が見つかりません（未保存の行なら URL を選択してから実行してください）" >&2
        exit 1
      fi

      exec ${waveOpen} "$url"
    '';
  };

  # URL を 1 つ受け取って、Wave の中なら web ブロック、外なら既定のブラウザで開く。
  # mplsOpen と同じ判定（WAVETERM_JWT の有無）。
  waveOpen = pkgs.writeShellScript "wave-open" ''
    url="$1"
    if [ -n "''${WAVETERM_JWT:-}" ]; then
      ${wshHere}/bin/wsh-here web open "$url" && exit 0
    fi
    exec ${if isDarwin then "/usr/bin/open" else "${pkgs.xdg-utils}/bin/xdg-open"} "$url"
  '';

  # mpls のプレビューはコードにフォントを指定しておらず（html の sans-serif のみ）、
  # ブラウザ既定の monospace には日本語や罫線が無いので別フォントに落ちて桁がずれる。
  # mpls には CSS を渡すオプションが無く、styles.css はバイナリに go:embed されているので、
  # ビルド前に端末と同じ Explex（日本語 2 桁幅の等幅。packages.nix で導入）を足す。
  # 本文も含めてページ全体を Explex にそろえる（html）。pre / code などはブラウザの
  # 既定スタイルが monospace を当てて html から継承しないので個別にも指定する。
  # 数式（KaTeX）はクラス単位で自前のフォントを指定しているのでそのまま。
  # Wave の web ブロックにもフォント設定は無い（web:* は zoom などのみ）。
  #
  # あわせて ```markmap のコードブロックをマインドマップとして描けるようにする
  # （mpls は mermaid と PlantUML だけ対応）。markmap のライブラリは CDN から読まずに
  # バイナリへ埋め込む（オフラインでも描ける）。mpls は決まったファイルしか配信しないので、
  # 配信済みの ws.js の前にライブラリ、後ろに描画処理（mpls-markmap.js）を連結する。
  # 版は実績のある 0.18.12（2025-06）と d3 7.9.0。上げるときは hash も更新する。
  mpls = pkgs.mpls.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      cat >> internal/previewserver/web/styles.css <<'EOF'

      html, pre, code, kbd, samp {
        font-family: "Explex Console NF", ui-monospace, monospace;
      }

      svg.markmap {
        display: block;
        width: 100%;
        height: 480px;
        --markmap-text-color: var(--text-color);
        --markmap-code-bg: var(--code-background-color);
        --markmap-font: 300 16px/20px "Explex Console NF", sans-serif;
      }
      EOF

      # mpls は ws.js を fmt.Sprintf(ws.js, port) で配信する（中の %d にポートを入れる）。
      # 連結するライブラリ側の % も書式指定として解釈されて壊れるので %% にしておく。
      ws=internal/previewserver/web/ws.js
      {
        sed 's/%/%%/g' ${markmapAssets.d3}
        echo
        sed 's/%/%%/g' ${markmapAssets.lib}
        echo
        sed 's/%/%%/g' ${markmapAssets.view}
        echo
        cat "$ws"
        echo
        sed 's/%/%%/g' ${./mpls-markmap.js}
      } > ws.js.new
      mv ws.js.new "$ws"
    '';
  });

  markmapAssets = {
    d3 = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/npm/d3@7.9.0/dist/d3.min.js";
      hash = "sha256-8glLv2FBs1lyLE/kVOtsSw8OQswQzHr5IfwVj864ZTk=";
    };
    lib = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/npm/markmap-lib@0.18.12/dist/browser/index.iife.js";
      hash = "sha256-7f4yGj/kbpwPCvg3AUWu4YCXXyQ/IkLw+BgaxCc+COE=";
    };
    view = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/npm/markmap-view@0.18.12/dist/browser/index.js";
      hash = "sha256-hh620grxiqowCHjUbWlXIqc2JcWLQPSSNq8Cfxi3Tgc=";
    };
  };

  # macOS 用: PATH の先頭に mplsOpen を `open` という名前で置いて mpls を起動する。
  # mpls が外部コマンドとして呼ぶのはブラウザ起動の open だけなので、影響はそこに閉じる。
  mplsDarwin = pkgs.writeShellScript "mpls" ''
    PATH=${
      pkgs.linkFarm "mpls-open-shim" [
        {
          name = "bin/open";
          path = mplsOpen;
        }
      ]
    }/bin:$PATH
    export PATH
    exec ${mpls}/bin/mpls "$@"
  '';
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
      nixfmt
      # スペル（codebook）・英語の文法（harper）。設定は language-server を参照
      codebook
      harper
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
        bufferline = "never";
        cursor-shape.insert = "bar";
        inline-diagnostics.cursor-line = "hint";
      };

      # markdown のプレビューをブラウザで開く（mpls の workspace command）。
      # mpls の README は C-m を例示しているが、端末では C-m = Enter なので使わない。
      keys.normal.space.m = ":lsp-workspace-command open-preview";

      # クリップボードの画像を images/ に保存してカーソル位置にリンクを挿入する。
      # %{buffer_name} は helix の cwd からの相対パス（cwd 外なら絶対パス）で、
      # シェルも同じ cwd で走るのでそのまま渡せる。
      keys.normal.space.i = '':insert-output ${pasteImage}/bin/hx-paste-image "%{buffer_name}"'';

      # カーソル位置（または選択範囲）の URL を開く。Wave の中なら web ブロックで開く。
      keys.normal.space.o = '':pipe-to ${openUrl}/bin/hx-open-url "%{buffer_name}" %{cursor_line} %{cursor_column}'';
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
        codebook = {
          command = "codebook-lsp";
          args = [ "serve" ];
          # グローバル辞書（words）は repo の modules/home/codebook.toml を直接読ませる。
          # hx の space+a → "Add to global dictionary" で codebook がこのファイルに単語を
          # 書き足すので、Nix ストアの読み取り専用 symlink にはできない。追加した単語は
          # git で管理する（"Add to dictionary" の方はプロジェクトの .helix/codebook.toml）。
          #
          # 注意 1: 必ず絶対パスで渡す。codebook 0.3.39 は README では ~/ に対応とあるが、
          # 起動時の読み込みでは ~ を展開せず（辞書なしで動く）、保存時だけ展開するため、
          # 空の設定に足した 1 語でこのファイルを丸ごと上書きしてしまう。
          # 注意 2: codebook は保存時に TOML を書き直すのでコメントは消える。説明はここに書き、
          # codebook.toml は codebook 自身の書式（words だけ、4 スペース）にそろえてある。
          config.globalConfigPath = "${config.home.homeDirectory}/dotfiles/modules/home/codebook.toml";
        };

        harper-ls = {
          command = "harper-ls";
          args = [ "--stdio" ];
          # スペルは codebook に任せる（同じ誤字が二重に出るのと、SplitWords が
          # "mpls" → "mp ls" のような的外れな提案を出すため）。
          # 残りは日本語まじりの文章とコードのコメントで誤検知ばかりになるルール
          # （この repo の .nix と README で数えて 200 件超 → 1 件）。文法系
          # （主語と動詞の一致など）は残している。
          config.harper-ls.linters = {
            SpellCheck = false;
            SplitWords = false;
            # 日本語の文やコメントの書き出しが小文字だと毎回出る
            SentenceCapitalization = false;
            UseTitleCase = false;
            # コマンド名の docker / markdown なども「Docker にしろ」と言われる
            OrthographicConsistency = false;
            # --flag や ... などコード片の記号に反応する
            Dashes = false;
            UnclosedQuotes = false;
            UseEllipsisCharacter = false;
            EllipsisLength = false;
            NumericRangeEnDash = false;
            # 日本語の読点を英語の文脈とみなして指摘する
            CommaFixes = false;
            ExpandStandardInputAndOutput = false;
          };
        };

        # markdown のライブプレビュー用 LSP。テーマは editor 側の osaka_jade に
        # 寄せる。`mpls --list-themes` に osaka-jade は無いので、同系統の暗い緑
        # である everforest-dark を代わりに使う。--no-auto を付けないとファイルを
        # 開いた時点でブラウザが立ち上がるので、space+m で明示的に開く運用にする。
        # ブラウザの開き方は上の mplsOpen を参照（Wave の中なら web ブロック）。
        mpls = {
          command = if isDarwin then "${mplsDarwin}" else "mpls";
          args = [
            "--theme"
            "everforest-dark"
            "--no-auto"
            # PlantUML はローカルのレンダリングサーバ（plantuml.nix が docker
            # compose で起動する plantuml-server コンテナ）に向ける。既定は
            # www.plantuml.com への外部 HTTP 呼び出しなので、UML を含む markdown を
            # 書くたびに図のソースが外部に送られてしまう。
            # --plantuml-server はホスト（host:port）だけを取り、パスは
            # --plantuml-path（既定 "plantuml"）が持つ。コンテナ側は BASE_URL=plantuml
            # で jetty のコンテキストパスをそこに合わせてあるので path は触らない。
            # TLS はローカルなので落とす。
            "--plantuml-server"
            "localhost:${toString config.local.plantuml.port}"
            "--plantuml-disable-tls"
          ]
          # macOS では `open -a <browser>` に渡されるのでアプリ名で指定する
          # （Wave の外で開くときに使われる）。
          # Linux では --browser がコマンドとして実行されるので mplsOpen を直接渡す。
          # Wave の外では xdg-open（既定のブラウザ）に落ちる。
          ++ [
            "--browser"
            (if isDarwin then "Safari" else "${mplsOpen}")
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
          language-servers = [ "nil" ] ++ spellServers;
          formatter.command = "nixfmt";
          auto-format = true;
        }
        {
          name = "markdown";
          language-servers = [
            "marksman"
            "mpls"
          ]
          ++ spellServers;
          formatter = prettierWith "markdown";
          auto-format = true;
        }
        {
          name = "yaml";
          language-servers = [
            "yaml-language-server"
            "codebook"
          ];
          formatter = prettierWith "yaml";
          auto-format = true;
        }
        {
          name = "toml";
          language-servers = [
            "taplo"
            "codebook"
          ];
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
          language-servers = [ "typescript-language-server" ] ++ spellServers;
          formatter = prettierWith "typescript";
          auto-format = true;
        }
        {
          name = "tsx";
          language-servers = [ "typescript-language-server" ] ++ spellServers;
          formatter = prettierWith "typescript";
          auto-format = true;
        }
        {
          name = "javascript";
          language-servers = [ "typescript-language-server" ] ++ spellServers;
          formatter = prettierWith "babel";
          auto-format = true;
        }
        {
          name = "jsx";
          language-servers = [ "typescript-language-server" ] ++ spellServers;
          formatter = prettierWith "babel";
          auto-format = true;
        }
        {
          name = "python";
          language-servers = [
            "pyright"
            "ruff"
          ]
          ++ spellServers;
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
          language-servers = [ "rust-analyzer" ] ++ spellServers;
          formatter.command = "rustfmt";
          auto-format = true;
        }
        {
          # コミットメッセージ（git commit で開く COMMIT_EDITMSG）。既定では LSP が無い。
          name = "git-commit";
          language-servers = spellServers;
        }
      ];
    };
  };
}
