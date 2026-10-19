# web-2: a prod web host with the short motd.
{ ren, ... }:
{
  ren.host.web-2 = {
    environment = ren.environment.prod;
    channel = ren.channel.stable;
    system = ren.system.x86_64-linux;
    addr = "10.0.1.11";
  };

  ren.aspects.quiet = {
    at = ren.host.web-2;
    excludes = [ ren.aspects.motd ];
    includes = [ ren.aspects.motd-short ];
  };
}
