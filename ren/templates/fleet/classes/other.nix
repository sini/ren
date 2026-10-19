# CLASSES: droid and terraform.
{
  ren,
  inputs,
  h,
  ...
}:
let
  inherit (ren.lib) and when;
  inherit (h) pkgsOf;
in
{
  droid = {
    at = ren.kinds.phone;
    into =
      { phone, ... }:
      ms: {
        nixOnDroidConfigurations.${phone.name} = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgsOf phone;
          modules = ms;
        };
      };
  };

  terraform = {
    at = and [
      ren.kinds.environment
      (when (s: s.environment.edge))
    ];
    into =
      { ... }:
      ms: {
        terraformConfigurations.dns = inputs.terranix.lib.terranixConfiguration {
          system = "x86_64-linux";
          modules = ms;
        };
      };
  };
}
