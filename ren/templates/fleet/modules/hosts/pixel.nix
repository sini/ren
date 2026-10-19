# pixel: the staging phone.
{ ren, ... }:
{
  ren.phone.pixel = {
    environment = ren.environment.staging;
    channel = ren.channel.stable;
    system = ren.system.aarch64-linux;
  };
}
