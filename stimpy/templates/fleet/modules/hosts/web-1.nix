# web-1: a prod web host on the latest kernel.
{ ren, ... }:
{
  ren.host.web-1 = {
    environment = ren.environment.prod;
    channel = ren.channel.stable;
    system = ren.system.x86_64-linux;
    addr = "10.0.1.10";
    settings.kernel.channel = "latest";
  };
}
