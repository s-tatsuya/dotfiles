{
  description = "TypeScript development environment with Node.js and pnpm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Node.jsのバージョンをここで管理 (nodejs_20, nodejs_22 など)
        nodejs = pkgs.nodejs_22;
        pnpm = pkgs.pnpm;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            pnpm
            # TypeScript本体とLSP
            typescript
            nodePackages.typescript-language-server
            # 便利ツール
            nodePackages.vscode-langservers-extracted # HTML/CSS/JSON LSP
          ];

          shellHook = ''
            # pnpm のストアパスがシステム側と衝突しないよう、プロジェクト内に配置する設定
            # これにより、Nix環境下でのパーミッションエラーを回避できます
            export PNPM_HOME="$PWD/.pnpm-home"
            export PATH="$PNPM_HOME:$PATH"

            echo "⬢ Node.js $(node -v) / pnpm $(pnpm -v) environment loaded"
            echo "🚀 TypeScript $(tsc -v) is ready"
          '';
        };
      }
    );
}
