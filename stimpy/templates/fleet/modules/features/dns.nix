# DNS: every machine emits an A record; the edge environment renders them with terranix.
{ ren, inputs, ... }:
let
  inherit (ren.lib) and when;
in
{
  ren.classes.terraform = {
    at = and [
      ren.kinds.environment
      (when (s: s.environment.edge))
    ];
    into = { ... }: ms: {
      terraformConfigurations.dns = inputs.terranix.lib.terranixConfiguration {
        system = "x86_64-linux";
        modules = ms;
      };
    };
  };

  ren.channels.records = {
    fold = ren.lib.fold.attrs;
    at = ren.kinds.machine;
    to = _: ren.environment.prod;
  };

  ren.aspects.dns = {
    at = ren.environment.prod;
    terraform = { records, lib, ... }: {
      resource.cloudflare_record = lib.mapAttrs (_: addr: {
        value = addr;
        type = "A";
      }) records;
    };
  };
}
