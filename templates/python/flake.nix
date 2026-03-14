{
  description = "Python 3.12 development environment with uv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Python 3.12 を指定
        python = pkgs.python312;

        # バイナリ wheel が共有ライブラリを見つけられるようにするためのリスト
        # (科学計算や機械学習ライブラリで必要になることが多い)
        runtimeLibs = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          glib
        ];
      in
      {
        # uv はそれ自体が高速なインストーラ・ビルダなので、
        # Nix側でパッケージをビルドする設定(default)はシンプルにします
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python
            uv
            ruff # Python用の高速リンター・フォーマッタ
          ];

          shellHook = ''
            # .venv をプロジェクトディレクトリ内に作成するように強制
            export UV_PYTHON_PREFERENCE=only-system

            # Nix環境で動かないバイナリ(wheel)を動くようにするマジック
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeLibs}:$LD_LIBRARY_PATH"

            echo "🐍 Python 3.12 (uv) shell loaded"
            echo "Tip: Run 'uv venv' to create a virtualenv and 'uv pip install' to manage packages."
          '';
        };
      }
    );
}
