# `wsh-here`: 今いる Wave のブロックに向けて wsh を実行するラッパー。
# waveterm.nix（zsh の wsh 関数）と helix.nix（space+o / space+m のプレビュー）から
# `import ./wsh-here.nix { inherit pkgs; }` で使う。
#
# なぜ要るか: wsh は環境変数 WAVETERM_BLOCKID / WAVETERM_TABID が指すタブに
# ブロックを足す。herdr のペインのシェルは herdr サーバーを起動した時点の Wave ブロックの
# 環境変数を引き継いだままなので、そのブロック（タブ）を閉じて別のブロックから herdr に
# つなぎ直すと、宛先が消えたタブのままになり "tab not found" で失敗する。
#
# 対処: herdr の中（HERDR_ENV=1）では、今 Wave のブロックで動いている herdr クライアント
# （`herdr server` ではない方）の環境変数から宛先を読み直す。クライアントは今のブロックから
# 起動されているので正しい値を持っている。複数のブロックでクライアントが動いているときは
# 一番新しく起動したもの（PID が最大）を使う。見つからなければ環境変数をそのまま使う。
{ pkgs }:
pkgs.writeShellApplication {
  name = "wsh-here";
  runtimeInputs = [ pkgs.procps ];
  text = ''
    real=""
    # PATH 上の wsh（Wave が自分の端末の PATH に足す）か、既定の置き場。
    # 置き場のパスに空白（Application Support）があるので 1 行ずつ読む。
    while IFS= read -r c; do
      if [ -n "$c" ] && [ -x "$c" ]; then
        real="$c"
        break
      fi
    done < <(type -ap wsh || true; echo "$HOME/Library/Application Support/waveterm/bin/wsh")
    if [ -z "$real" ]; then
      echo "wsh-here: wsh が見つかりません（Wave の外では使えません）" >&2
      exit 127
    fi

    if [ "''${HERDR_ENV:-}" = "1" ]; then
      client=""
      for pid in $(pgrep -x herdr || true); do
        # サーバーは `herdr server`。引数のないものがクライアント。
        if [ "$(ps -o command= -p "$pid" | awk '{print $2}')" != "server" ]; then
          if [ -z "$client" ] || [ "$pid" -gt "$client" ]; then
            client="$pid"
          fi
        fi
      done
      if [ -n "$client" ]; then
        # ps eww は環境変数をコマンドラインの後ろに空白区切りで出す（値に空白は無い）。
        for kv in $(ps eww -o command= -p "$client" | tr ' ' '\n' | grep -E '^WAVETERM_(BLOCKID|TABID|JWT)=' || true); do
          export "''${kv?}"
        done
      fi
    fi

    exec "$real" "$@"
  '';
}
