# lb: the prod load balancer.
{ ren, ... }:
{
  ren.host.lb = {
    environment = ren.environment.prod;
    channel = ren.channel.stable;
    system = ren.system.x86_64-linux;
    addr = "10.0.1.1";
  };

  ren.aspects.lb = {
    at = ren.host.lb;
    includes = [
      ren.aspects.haproxy
      ren.aspects.monitoring
    ];
  };
}
