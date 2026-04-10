{
  description = "Multi-platform Dotfiles Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # 共通のパッケージ設定を関数化
      mkPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "github-copilot-cli"
          "vscode"
        ];
      };
    in {
      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust development environment template";
        };
        # デフォルトを設定しておくと #名前 を省略できます
        default = self.templates.rust;
      };
      homeConfigurations = {
        # Mac用 (make apply の際に .#default または .#mac と指定)
        "mac" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "aarch64-darwin";
          modules = [ ./home.nix ];
        };

        # Ubuntu用 (make apply の際に .#ubuntu と指定)
        "ubuntu" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          modules = [ ./home.nix ];
        };
        
        # 以前の "default" も残しておく場合（Macをデフォルトにする例）
        "default" = self.homeConfigurations.mac;
      };
    };
}
