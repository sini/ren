let
  lib = import "${(import ../lock.nix).nixpkgs}/lib";
  stimpy = import ../. { inherit lib; };
in
{
  lib = import ./lib { inherit lib stimpy; };
  templates = import ../templates/fleet/tests {
    inherit lib stimpy;
    # no pkgs in tier 1: forcing legacyPackages throws
    nixpkgs = {
      inherit lib;
      outPath = (import ../lock.nix).nixpkgs;
      legacyPackages = throw "no pkgs in tier1";
    };
  };
}
