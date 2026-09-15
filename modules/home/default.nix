{ ... }:
{
  imports = [
    # プラットフォーム差分の受け皿。中身は自身で isLinux / isDarwin を見て
    # 無効化するので、macOS / Ubuntu どちらの構成からも無条件に import してよい。
    ./linux.nix

    # 機能別モジュール
    ./packages.nix
    ./git.nix
    ./gh.nix
    ./zsh.nix
    ./starship.nix
    ./fzf.nix
    ./bat.nix
    ./helix.nix
    ./plantuml.nix
    ./ghostty.nix

    # macOS 専用（colima + docker CLI）。中身は isDarwin で閉じてあるので
    # Ubuntu 構成から import しても何も生成されない。あちらの Docker Engine は
    # scripts/ubuntu-bootstrap.sh の担当。
    ./docker.nix
  ];
}
