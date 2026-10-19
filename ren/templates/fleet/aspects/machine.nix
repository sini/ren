# ASPECTS: machine-wide activators; `at` activates, no `at` = only where included.
{
  ren,
  inputs,
  h,
  ...
}:
let
  inherit (ren.lib) and has;
  inherit (h) metal;
in
{
  base = {
    at = ren.kinds.machine;
    os =
      { machine, overlays, ... }:
      {
        networking.hostName = machine.name;
        nixpkgs.overlays = overlays;
      };
    records = { machine, ... }: { ${machine.name} = machine.addr; };
  };
  deploy-record = {
    at = metal;
    deployment =
      { host, meta, ... }:
      {
        address = host.addr;
        user = "deploy";
        tags = meta;
      };
  };

  # bundle: each key lands where its class lives
  hm-module = {
    at = ren.kinds.machine;
    nixos = { host, ... }: { imports = [ host.channel.home-manager.nixosModules.home-manager ]; };
    darwin = { mac, ... }: { imports = [ mac.channel.home-manager.darwinModules.home-manager ]; };
  };
  secrets = {
    at = ren.kinds.host;
    nixos.imports = [ inputs.agenix.nixosModules.default ];
    flake-inputs = { ... }: { agenix.url = "github:ryantm/agenix"; };
  };

  vm = {
    at = ren.kinds.guest;
    nixos.imports = [ inputs.microvm.nixosModules.microvm ];
    flake-inputs = { ... }: { microvm.url = "github:microvm-nix/microvm.nix"; };
  };
  vm-host = {
    at = and [
      metal
      (has ren.kinds.guest)
    ];
    nixos.imports = [ inputs.microvm.nixosModules.host ];
  };

  # a function value: wrap it in `{ ... }:`
  unstable-overlay = {
    at = ren.fleet.main;
    overlays =
      { ... }:
      _final: prev: { inherit (inputs.nixpkgs-unstable.legacyPackages.${prev.system}) helix; };
  };
}
