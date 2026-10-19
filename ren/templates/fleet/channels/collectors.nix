# CHANNELS: with `into`: data collectors (not module systems, so not classes).
{
  ren,
  inputs,
  h,
  ...
}:
let
  inherit (h) metal;
  inherit (ren.lib.fold) attrs;
in
{
  packages = {
    fold = attrs;
    at = ren.kinds.system;
    to = e: e;
    into = { system, ... }: pkgs': { packages.${system.name} = pkgs'; };
  };
  # fed by the nixos collector
  colmena = {
    fold = attrs;
    at = metal;
    to = _: ren.fleet.main;
    into =
      { ... }:
      nodes: {
        colmenaHive = inputs.colmena.lib.makeHive (
          { meta.nixpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; } // nodes
        );
      };
  };
  # fed by the nixos collector
  age-manifest = {
    fold = attrs;
    at = metal;
    to = _: ren.fleet.main;
    into = { ... }: m: { ageManifest = m; };
  };
}
