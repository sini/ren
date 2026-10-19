# studio: the staging mac.
{ ren, ... }:
{
  ren.mac.studio = {
    environment = ren.environment.staging;
    channel = ren.channel.stable;
    system = ren.system.aarch64-darwin;
    addr = "10.0.2.30";
  };
}
