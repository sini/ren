# Shared fixtures for the fleet rows tests (not a test module).
{ ren, lib }:
rec {
  stubs = import ../fleet-stubs.nix { inherit lib; };
  fleet = import ../../fleet/fleet.nix;
  load = ren.load { inherit lib; } stubs;
  out = load fleet;
  nixos = out.nixosConfigurations;
  cfg = h: nixos.${h}.config;
  ciVm = (cfg "stage").microvm.vms.ci;
  # the guest's forwarded modules, evaluated the way microvm would
  ci =
    (stubs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ciVm.config ];
    }).config;
  studio = out.darwinConfigurations.studio.config;
  laptop = out.homeConfigurations.alice-laptop.config;
  # every nixos-shaped machine config, guest included
  machines = lib.mapAttrs (h: _: cfg h) nixos // {
    inherit ci studio;
  };
  devicesOf = u: c: lib.attrNames c.home-manager.users.${u}.services.syncthing.settings.devices;
  aliceScopes = [
    "alice-laptop"
    "ci"
    "lb"
    "pixel"
    "stage"
    "studio"
    "web-1"
    "web-2"
  ];
}
