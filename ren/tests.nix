let
  inputs = import ./templates/ci/with-inputs.nix { };
  inherit (inputs.nixpkgs) lib;
in
import ./templates/ci/tests.nix
// {
  templates = import ./templates/fleet/tests {
    inherit lib;
    impl = import ./. { gen = import inputs.gen.outPath { }; };
    # no pkgs in tier 1: forcing legacyPackages throws
    nixpkgs = {
      inherit lib;
      inherit (inputs.nixpkgs) outPath;
      legacyPackages = throw "no pkgs in tier1";
    };
  };
}
