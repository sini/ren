# ASPECTS: included-only service aspects and their activators.
{
  ren,
  ...
}:
let
  inherit (ren.lib) anyOf;
in
{
  # included only
  nginx = {
    nixos.services.nginx.enable = true;
    meta = { ... }: "web";
    backends = { host, ... }: host.addr;
    persist = { ... }: "/var/lib/nginx";
  };
  haproxy.nixos =
    { backends, lib, ... }:
    {
      services.haproxy.enable = true;
      services.haproxy.config = lib.concatMapStrings (a: "  server ${a} ${a}:80 check\n") backends;
    };
  monitoring.nixos =
    { scrape, ... }:
    {
      services.prometheus.scrapeConfigs = map (j: {
        job_name = j.job;
        static_configs = [ { targets = [ j.target ]; } ];
      }) scrape;
    };

  # activators
  lb = {
    at = ren.host.lb;
    includes = [
      ren.aspects.haproxy
      ren.aspects.monitoring
    ];
  };
  web = {
    at = anyOf [
      ren.host.web-1
      ren.host.web-2
      ren.host.stage
    ];
    includes = [ ren.aspects.nginx ];
  };
}
