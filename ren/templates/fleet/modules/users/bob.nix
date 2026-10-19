# bob: deploy group; the hosts bob lives on run docker.
{ ren, ... }:
let
  inherit (ren.lib) and has;
in
{
  ren.user.bob = {
    groups = [ ren.group.deploy ];
  };

  ren.aspects.docker = {
    at = and [
      ren.kinds.host
      (has ren.user.bob)
    ]; # the hosts bob lives on
    nixos.virtualisation.docker.enable = true;
    persist = { ... }: "/var/lib/docker";
  };
}
