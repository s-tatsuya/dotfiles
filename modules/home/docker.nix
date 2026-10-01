{ config, lib, pkgs, ... }:
{
  # colima VM のスペックは `colima-up` の起動引数として渡す。リテラルをスクリプトに
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
      # 8 だと VM 内のページキャッシュが割り当てを埋めきり、ホストに半分しか
      # 残らなかった。docker compose で数個のコンテナを動かす程度なら 4 で足りる。
      default = 4;
      description = "colima VM に割り当てるメモリ（GiB）。VM が一度使った分はホストに返らない。";
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

    postStart = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        `colima-up` が VM の起動後に順に実行するスクリプト。
        Docker に乗る常駐サービス（plantuml.nix など）が起動処理を足すのに使う。
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
  # home.packages にも何も足さない。
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

      # VM は常駐させず、使うときだけ `colima-up` で起動する。以前はログイン時に
      # launchd agent で立ち上げていたが、VM のメモリはホストから取られたまま
      # 返ってこないので、Docker を使わない日も 16GiB のうち数 GiB を抱えることになる。
      #
      # 素の `colima start` ではなくラッパーを通すのは 2 つの理由から。
      #   1. スペックを毎回明示的に渡すため。colima は --save-config（既定 true）で
      #      これを ~/.colima/default/colima.yaml に書き戻すので、ここが唯一の正になり、
      #      値を変えて switch → `colima stop` → `colima-up` で既存 VM にも反映される。
      #   2. 起動後のフック（local.colima.postStart）を流すため。plantuml.nix が
      #      ここに `docker compose up -d` を足している。
      #
      # launchd の外（対話シェル）から叩くので、`colima start` は VM を起動したら
      # 制御を返してよい（lima の hostagent はデーモンとして残る）。止めるのは
      # 素の `colima stop`。
      (pkgs.writeShellScriptBin "colima-up" ''
        set -eu
        ${lib.getExe pkgs.colima} start ${
          lib.escapeShellArgs (
            [
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
            ++ lib.optional config.local.colima.rosetta "--vz-rosetta"
          )
        }
        ${lib.concatMapStrings (hook: "${hook}\n") config.local.colima.postStart}
      '')
    ];
  };
}
