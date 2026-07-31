{ ... }:
{
  # GitHub への認証は SSH 鍵ではなく gh（＝HTTPS + OAuth トークン）に一本化する。
  # 理由は README の「GitHub 認証方式」を参照。
  programs.gh = {
    enable = true;

    # clone / PR 作成時に gh が組み立てる URL を HTTPS にする（既定は ssh）。
    settings.git_protocol = "https";

    # gitCredentialHelper.enable は default = true なので明示不要。
    # https://github.com と https://gist.github.com に対して
    #   credential."https://github.com".helper = [ "" "gh auth git-credential" ]
    # が git.nix 側の設定にマージされる。先頭の "" が既存ヘルパー
    # （macOS 既定の osxkeychain）を該当ホストについてリセットするため、
    # ヘルパーが二重登録されて認証情報が食い違うことはない。
  };

  # トークン自体は宣言的に管理しない（フレークの内容は world-readable な
  # Nix ストアにコピーされるため）。マシンごとに一度 `gh auth login` を実行する。
}
