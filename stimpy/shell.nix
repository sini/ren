{
  pkgs ? import (import ./lock.nix).nixpkgs { },
}:
pkgs.mkShell {
  buildInputs = [
    pkgs.nix-unit
    pkgs.treefmt
    pkgs.nixfmt
    pkgs.just
  ];
}
