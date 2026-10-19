# ASPECTS: aspects fed by or feeding channels (sync, tools, dns, scrape).
{
  ren,
  inputs,
  ...
}:
let
  inherit (ren.lib) is;
in
{
  sync = {
    at = ren.kinds.user;
    devices = { parent, ... }: parent.name;
    persist = { user, ... }: "/home/${user.name}/.local/state/syncthing";
    homeManager =
      {
        devices,
        parent,
        lib,
        ...
      }:
      {
        services.syncthing.enable = true;
        services.syncthing.settings.devices = lib.genAttrs devices (_: { });
        services.syncthing.tray.enable = is ren.aspects.desktop parent; # same `is` as everywhere
      };
  };

  tools = {
    at = ren.kinds.system;
    packages = { system, ... }: { inherit (inputs.nixpkgs.legacyPackages.${system.name}) hello; };
  };

  dns = {
    at = ren.environment.prod;
    terraform =
      { records, lib, ... }:
      {
        resource.cloudflare_record = lib.mapAttrs (_: addr: {
          value = addr;
          type = "A";
        }) records;
      };
  };

  replica-scrape = {
    at = ren.kinds.replica;
    scrape =
      {
        db,
        region,
        replica,
        ...
      }:
      {
        job = replica.name;
        target = "${db.zone}.${region.zone}:9090";
      };
  };

}
