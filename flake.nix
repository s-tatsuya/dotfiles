{
  description = "S-Tatsuya's Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # herdr（AI コーディングエージェント用のターミナルワークスペース管理）
    # nixpkgs は follows させない: 向こうは nixos-unstable + rust-overlay 前提のため
    herdr.url = "github:herdrdev/herdr";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, herdr, nix-homebrew, homebrew-core, homebrew-cask }:
  let
    username = "s-tatsuya";
    system = "aarch64-darwin";   # M1/M2/M3 は aarch64-darwin
  in
  {
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username; };
      modules = [
        ./hosts/mac/default.nix

        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs username; };
          home-manager.users.${username} = import ./home/${username}.nix;
        }

        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = username;
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
            mutableTaps = false;
          };
        }
      ];
    };
  };
}
