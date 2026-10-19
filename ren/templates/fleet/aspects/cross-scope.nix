# ASPECTS: cross-scope and per-host activation by predicate.
{
  ren,
  ...
}:
let
  inherit (ren.lib) and within has;
in
{
  # cross-scope by predicate
  ssh-agent = {
    at = and [
      ren.kinds.user
      (within ren.kinds.machine)
    ];
    homeManager.services.ssh-agent.enable = true;
  };
  # the hosts bob lives on
  docker = {
    at = and [
      ren.kinds.host
      (has ren.user.bob)
    ];
    nixos.virtualisation.docker.enable = true;
    persist = { ... }: "/var/lib/docker";
  };
  htop = {
    at = and [
      ren.user.alice
      (within ren.host.web-1)
    ];
    homeManager.programs.htop.enable = true;
  };

  desktop = {
    at = ren.host.stage;
    nixos.services.xserver.enable = true;
  };
  dock = {
    at = ren.kinds.mac;
    darwin.system.defaults.dock.autohide = true;
  };
  # lands only on mac users
  tiling = {
    at = ren.kinds.user;
    homeDarwin.programs.aerospace.enable = true;
  };

  motd = {
    at = ren.kinds.machine;
    os.users.motd = "managed by ren";
  };
  motd-short.os.users.motd = "ren"; # included only
  quiet = {
    at = ren.host.web-2;
    excludes = [ ren.aspects.motd ];
    includes = [ ren.aspects.motd-short ];
  };
}
