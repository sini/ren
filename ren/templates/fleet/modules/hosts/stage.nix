# stage: the staging host, with a desktop.
{ ren, ... }:
{
  ren.host.stage = {
    environment = ren.environment.staging;
    channel = ren.channel.edge;
    system = ren.system.x86_64-linux;
    addr = "10.0.2.10";
  };

  ren.aspects.desktop = {
    at = ren.host.stage;
    nixos.services.xserver.enable = true;
  };
}
