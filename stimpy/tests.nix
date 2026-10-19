let
  lib = import "${(import ./lock.nix).nixpkgs}/lib";
  stimpy = import ./. { inherit lib; };
  # one suite per tests/*.nix; `_` files are helpers
  suites =
    lib.mapAttrs'
      (f: _: {
        name = lib.removeSuffix ".nix" f;
        value = import (./tests + "/${f}") { inherit lib stimpy; };
      })
      (lib.filterAttrs (f: _: lib.hasSuffix ".nix" f && !lib.hasPrefix "_" f) (builtins.readDir ./tests));
in
{
  lib = suites;
  templates = import ./templates/fleet/tests {
    inherit lib;
    impl = stimpy;
    # no pkgs in tier 1: forcing legacyPackages throws
    nixpkgs = {
      inherit lib;
      outPath = (import ./lock.nix).nixpkgs;
      legacyPackages = throw "no pkgs in tier1";
    };
  };
}
