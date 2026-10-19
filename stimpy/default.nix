{
  lib ? import "${(import ./lock.nix).nixpkgs}/lib",
}:
import ./lib { inherit lib; }
