# Tier-1 tests of templates/fleet against the evalFleet RESULT API (design note).
# No non-nixpkgs input and no realized system may be forced here.
{
  lib,
  stimpy,
  nixpkgs,
}:
let
  # the template's own lock pins import-tree; stimpy does not depend on it
  import-tree = import (
    builtins.fetchTree (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes.import-tree.locked
  );
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
  fleet = import-tree ../modules;
  r = stimpy.evalFleet inputs fleet;
  # ev extra: the same fleet plus one extra module
  ev =
    extra:
    stimpy.evalFleet inputs {
      imports = [
        fleet
        extra
      ];
    };
  args = { inherit lib r ev; };
  suites = ((import-tree.withLib lib).filterNot (lib.hasSuffix "/default.nix")).leaves ./.;
in
# one suite per file: scopes.nix -> scopes
lib.listToAttrs (
  map (f: lib.nameValuePair (lib.removeSuffix ".nix" (baseNameOf f)) (import f args)) suites
)
