# Tier-1 tests of templates/fleet against the evalFleet RESULT API (design note).
# No non-nixpkgs input and no realized system may be forced here.
{
  lib,
  stimpy,
  nixpkgs,
}:
let
  unfetched = n: throw "unfetched ${n}";
  inputs =
    lib.genAttrs [
      "nixpkgs-unstable"
      "home-manager"
      "home-manager-unstable"
      "nix-darwin"
      "colmena"
      "nix-on-droid"
      "terranix"
      "agenix"
      "microvm"
      "impermanence"
    ] unfetched
    // {
      inherit nixpkgs;
      self = unfetched "self";
    };
  r = stimpy.evalFleet inputs ../fleet.nix;
  # ev extra: the same fleet plus one extra module
  ev =
    extra:
    stimpy.evalFleet inputs {
      imports = [
        ../fleet.nix
        extra
      ];
    };
  args = { inherit lib r ev; };
in
{
  scopes = import ./scopes.nix args;
  activation = import ./activation.nix args;
  pools = import ./pools.nix args;
  collect = import ./collect.nix args;
  errors = import ./errors.nix args;
}
