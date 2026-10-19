{
  lib ? import "${(import ./lock.nix).nixpkgs}/lib",
}:
let
  # nest pattern: each lib/*.nix is `stimpy: { <name> = …; }` and sees the merged set
  files = lib.filter (lib.hasSuffix ".nix") (lib.attrNames (builtins.readDir ./lib));
  stimpy = lib.foldl' (acc: f: acc // import (./lib + "/${f}") stimpy) { inherit lib; } files;
in
removeAttrs stimpy [ "lib" ]
