{ config, lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # docker CLI の在り処は OS で違う。ここが mac / Ubuntu の唯一の実質的な差分。
  #   macOS : modules/home/docker.nix が入れる Nix の docker（colima の VM に繋がる）。
  #   Ubuntu: scripts/ubuntu-bootstrap.sh が入れる apt の docker-ce-cli。
  # launchd / systemd から起動されるスクリプトは PATH が痩せているので絶対パスで書く。
  dockerBin = if isDarwin then "${pkgs.docker}/bin/docker" else "/usr/bin/docker";

  composeFile = "${config.xdg.configHome}/plantuml/compose.yaml";

  # compose ファイルは Nix 側で組み立てる。手書き YAML と違いポート番号の
  # 文字列化やクォートを間違えようがなく、local.plantuml.port と必ず整合する。
  composeSource = (pkgs.formats.yaml { }).generate "plantuml-compose.yaml" {
    # プロジェクト名。省略すると compose ファイルを置いたディレクトリ名から
    # 推測される（symlink は解決されないので ~/.config/plantuml/ → "plantuml"）。
    # 暗黙の推測に任せるとネットワーク名や `docker compose ls` の表示が
    # 置き場所次第で変わるので明示する。
    name = "plantuml";

    services.plantuml = {
      # jetty 版が upstream の推奨。tag は flake.lock の管轄外なので、
      # 固定したい場合は image に @sha256:... を付ける
      # （2026-09-15 時点の jetty:
      #  sha256:5f6f99ec2fc11c8236e80630d622b0ba22b8d9301b39b18db4bb2b95cae87781）。
      image = "plantuml/plantuml-server:jetty";
      container_name = "plantuml-server";

      # これが「PC 起動時に立ち上がる」の実体。docker daemon が起きるたびに
      # daemon 自身がコンテナを起こし直すので、mac なら colima の VM 起動時、
      # Ubuntu なら docker.service の起動時に自動で復帰する。
      # `docker compose down` / `docker stop` で明示的に止めたときだけ復帰しない
      # （always ではなくこちらを使う理由）。
      restart = "unless-stopped";

      # 既定のイメージはアプリを ROOT コンテキストに配置するので
      # /svg/<encoded> で応答する。一方 mpls の --plantuml-path の既定は
      # "plantuml" で /plantuml/svg/<encoded> を叩く。BASE_URL を渡すと
      # jetty のコンテキストパスがそこに変わるので、mpls 側を素のまま使える。
      environment.BASE_URL = "plantuml";

      # 127.0.0.1 に限定して publish する。0.0.0.0 だと同じ LAN の他人に
      # レンダリングサーバを開放してしまう。
      ports = [ "127.0.0.1:${toString config.local.plantuml.port}:8080" ];
    };
  };

  # ログイン時に compose を当てるスクリプト。
  #
  # `up -d` は冪等で、コンテナが無ければ作り、compose ファイルが変わっていれば
  # 作り直し、同じなら何もしない。つまり switch 後の反映もこれ 1 本で足りる。
  startScript = pkgs.writeShellScript "plantuml-server-up" ''
    set -eu

    # docker daemon が応答するまで待つ。macOS では colima の VM 起動（初回は
    # イメージのダウンロードを含む）に時間がかかるうえ、launchd は agent 間の
    # 順序関係を持たないので、ログイン直後はここで必ず待たされる。
    # 3 分待って駄目なら諦める。コンテナ自体は restart ポリシーで
    # daemon 側が起こし直すので、ここで失敗しても致命的ではない。
    i=0
    while [ "$i" -lt 90 ]; do
      if ${dockerBin} info >/dev/null 2>&1; then
        exec ${dockerBin} compose -f ${lib.escapeShellArg composeFile} up -d --remove-orphans
      fi
      ${pkgs.coreutils}/bin/sleep 2
      i=$((i + 1))
    done

    echo "docker daemon に 180 秒以内に接続できませんでした。plantuml-server は起動していません。" >&2
    exit 1
  '';
in
{
  # ポートは helix.nix の mpls 側（--plantuml-server）と対で使うので、
  # 両方にリテラルを書かずオプションとして公開する。
  options.local.plantuml.port = lib.mkOption {
    type = lib.types.port;
    default = 45123;
    description = "PlantUML サーバをホスト側で公開するポート（コンテナ内は 8080 固定）。";
  };

  config = {
    # ~/.config/plantuml/compose.yaml。xdg.configFile は xdg.enable と無関係に
    # 使えるので、xdg.enable が false の macOS でも ~/.config 以下に置かれる。
    # 手で `docker compose -f ~/.config/plantuml/compose.yaml logs` などを
    # 叩けるよう、Nix ストア直リンクではなく分かる場所に出しておく。
    xdg.configFile."plantuml/compose.yaml".source = composeSource;

    # 常駐の入口は OS ごとに別物なので、同じスクリプトを 2 通りに登録する。
    # ただし以前の「JVM を常駐させる」構成と違い、ここで登録するのは
    # `docker compose up -d` を 1 回叩くだけのワンショット。
    # プロセスを抱え続けるのは docker daemon 側なので、launchd / systemd の
    # ジョブは即座に終了してよく、KeepAlive や Restart は要らない。
    #
    # macOS: launchd。home-manager の launchd.enable は非 darwin では既定 false で、
    #   agents を定義しても plist が生成されず黙って無視される。
    launchd.agents.plantuml-server = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [ "${startScript}" ];
        RunAtLoad = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/plantuml-server.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/plantuml-server.log";
      };
    };

    # Linux: systemd --user。Ubuntu は systemd が PID 1 なのでそのまま使える。
    #   ログイン時に 1 回走る。RemainAfterExit でユニットを active のまま保ち、
    #   `systemctl --user status plantuml-server` で当てた形跡が見えるようにする。
    #   ログは journald（`journalctl --user -u plantuml-server`）。
    systemd.user.services.plantuml-server = lib.mkIf (!isDarwin) {
      Unit = {
        Description = "PlantUML server (docker compose)";
        After = [ "network.target" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${startScript}";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
