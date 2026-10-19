# INSTANCES: fleet-wide data.
{
  ren,
  inputs,
  ...
}:
{
  fleet.main = { };
  system = {
    x86_64-linux = { };
    aarch64-linux = { };
    aarch64-darwin = { };
  };
  channel = {
    stable = {
      nixpkgs = inputs.nixpkgs;
      home-manager = inputs.home-manager;
      darwin = inputs.nix-darwin;
    };
    edge = {
      nixpkgs = inputs.nixpkgs-unstable;
      home-manager = inputs.home-manager-unstable;
    };
  };
  group = {
    ops = { };
    admin.members = [ ren.group.ops ];
    deploy = { };
  };
  environment = {
    prod = {
      grants = [ ren.group.admin ];
      edge = true;
      settings.kernel.channel = "lts";
    };
    staging = {
      grants = [
        ren.group.admin
        ren.group.deploy
      ];
      inherits = ren.environment.prod;
    };
  };
}
