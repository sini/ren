let
  inputs = import ./templates/ci/with-inputs.nix { };
  impl = import ./. { gen = import inputs.gen.outPath { }; };
  lib = impl.genLib;
in
import ./templates/ci/tests.nix
// {
  templates = import ./templates/fleet/tests {
    inherit lib impl;
    # no pkgs, no nixpkgs in tier 1: forcing either throws
    nixpkgs = {
      inherit lib;
      outPath = throw "no nixpkgs in tier1";
      legacyPackages = throw "no pkgs in tier1";
    };
  };
}
