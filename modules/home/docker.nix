{ config, lib, pkgs, ... }:
{
  # colima VM のスペックは launchd の起動引数として渡す。リテラルを plist の中に
  # 直接書くと外から見えないので、plantuml.nix の local.plantuml.port と同じ方針で
  # オプションとして公開し、値の置き場をここ 1 箇所に集める。
  #
  # options は config と違って mkIf で囲めない（評価前に型が必要）ため、宣言自体は
  # 両 OS で行われる。Linux 側では下の config が丸ごと無効化されるので参照されない。
  options.local.colima = {
    cpus = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = "colima VM に割り当てる CPU 数（ホストは 8 コア）。";
    };

    memory = lib.mkOption {
      type = lib.types.numbers.positive;
      default = 8;
      description = "colima VM に割り当てるメモリ（GiB）。ホストの 16GiB から静的に確保される。";
    };

    disk = lib.mkOption {
      type = lib.types.ints.positive;
      default = 100;
      description = ''
        colima VM のディスクサイズ（GiB）。スパースイメージなので、実際に消費するのは
        イメージとコンテナが使った分だけ。あとから縮めることはできない。
      '';
    };

    rosetta = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        amd64 イメージを Rosetta で実行する（vmType = vz のときのみ有効）。
        ホスト側に Rosetta 2 が必要: `softwareupdate --install-rosetta`。
      '';
    };
  };

  # ── ここから下は macOS 専用 ────────────────────────────────────────────────
  # Ubuntu には colima を入れない。あちらは scripts/ubuntu-bootstrap.sh が Docker 公式
  # apt リポジトリから Docker Engine（dockerd）を入れており、Linux カーネルがそのまま
  # 使えるので VM を挟む理由がない。colima は「macOS に Linux カーネルを用意する」ための
  # 道具なので、役割が重複するどころか docker CLI とコンテキストを奪い合う。
  #
  # よって config 全体を isDarwin で閉じる。Linux での評価結果は空になり、
  # home.packages にも launchd（そもそも Linux では無効）にも何も足さない。
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    home.packages = [
      # colima 本体。nixpkgs の colima は lima-full / qemu / krunkit を PATH に差し込む
      # ラッパーなので、limactl などを別途 home.packages に入れる必要はない。
      pkgs.colima

      # docker CLI。nixpkgs の docker は darwin では clientOnly でビルドされる
      # （dockerd は Linux バイナリなので、それは VM の中で colima が動かす）。
      # buildx と compose は cli-plugins として同梱されているので、
      # `docker buildx` / `docker compose` は追加パッケージ無しで動く。
      pkgs.docker
    ];

    # ログイン時に VM を起動する。plantuml.nix と同じく launchd（macOS 専用）を使う。
    #
    # `colima start` は VM を起動したら制御を返すが、lima の hostagent は
    # このプロセスの子として残る。launchd は（AbandonProcessGroup を立てない限り）
    # ジョブのメインプロセス終了時に残りのプロセスグループを回収するので、
    # そのままだと起動直後に VM ごと道連れになる。
    # --foreground で colima を SIGINT/SIGTERM 待ちのまま常駐させ、
    # ジョブの寿命と VM の寿命を一致させる（Homebrew の colima service も同じ形）。
    launchd.agents.colima = {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe pkgs.colima)
          "start"
          "--foreground"

          # スペックは毎回明示的に渡す。colima は --save-config（既定 true）で
          # これを ~/.colima/default/colima.yaml に書き戻すので、ここが唯一の正になり、
          # 値を変えて darwin-rebuild switch → 再起動すれば既存 VM にも反映される。
          "--cpus"
          (toString config.local.colima.cpus)
          "--memory"
          (toString config.local.colima.memory)
          "--disk"
          (toString config.local.colima.disk)

          # vz = Apple の Virtualization.framework。qemu より速く、virtiofs と
          # Rosetta が使えるのはこちらだけ。現行 colima の既定値でもあるが、
          # 上流の既定が変わってもここの意図が変わらないよう明示しておく。
          "--vm-type"
          "vz"

          # ホストの ~ を VM に渡す方式。virtiofs は vz 専用で、sshfs / 9p より速い。
          "--mount-type"
          "virtiofs"
        ]
        ++ lib.optional config.local.colima.rosetta "--vz-rosetta";

        # colima は VM 起動後に docker CLI を呼んで
        # `docker context create colima` / `docker context use colima` を実行する
        # （environment/container/docker/context.go）。launchd の PATH は
        # /usr/bin:/bin:/usr/sbin:/sbin しか無く docker が見つからないので、
        # ここで足しておかないとコンテキストが作られず `docker ps` が素の
        # /var/run/docker.sock を見に行って失敗する。
        # /usr/bin 以下も残す: colima / limactl が sw_vers や ssh を呼ぶ。
        EnvironmentVariables = {
          PATH = "${pkgs.docker}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };

        RunAtLoad = true;

        # 異常終了したときだけ起こし直す。`launchctl kill TERM` で止めたときは
        # --foreground が VM を畳んで正常終了（exit 0）するので、launchd は
        # 再起動しない。KeepAlive = true にするとここで無限に起動し直してしまう。
        KeepAlive.SuccessfulExit = false;

        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/colima.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/colima.log";
      };
    };
  };
}
