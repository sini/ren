# ci: a staging guest that runs on stage.
{ ren, ... }:
{
  ren.guest.ci = {
    environment = ren.environment.staging;
    channel = ren.channel.stable;
    system = ren.system.x86_64-linux;
    addr = "10.0.2.20";
    on = ren.host.stage;
  };
}
