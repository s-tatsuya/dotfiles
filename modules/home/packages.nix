{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    tree
  ] ++ [
    # nixpkgs にないので flake input から。system は評価するホストごとに解決されるので Linux でもそのまま動く
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
