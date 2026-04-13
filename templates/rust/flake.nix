{
  description = "A highly optimized Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    naersk.url = "github:nix-community/naersk/master";
  };

  outputs = { self, nixpkgs, utils, rust-overlay, naersk }:
    utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        # ツールチェーンの定義（rust-analyzerやclippyもセットで取得）
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
        };

        naersk-lib = pkgs.callPackage naersk {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };
      in
      {
        # `nix build` で実行ファイルをビルド
        packages.default = naersk-lib.buildPackage {
          root = ./.;
          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = with pkgs; [ openssl ];
        };

        # `nix develop` で入る開発環境
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
            nil           # 言語サーバー (LSP)
            nixpkgs-fmt   # フォーマッタ
          ];

          buildInputs = with pkgs; [
            rustToolchain
            openssl
            pre-commit
            cargo-edit    # cargo add などが便利になる
            cargo-watch   # 自動再実行
            direnv
            nix-direnv
          ];

          # VSCodeの rust-analyzer が標準ライブラリのソースを見つけられるようにする
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";

          shellHook = ''
            echo "🦀 Rust Dev Environment with Flakes & Naersk"
            cargo --version
          '';
        };
      }
    );
}
