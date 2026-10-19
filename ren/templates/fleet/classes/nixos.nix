# CLASSES: nixos (gen-aspects `class`); into returns top-level options.
{
  ren,
  lib,
  h,
  ...
}:
let
  inherit (h) metal pkgsOf;
in
{
  nixos = [
    {
      at = metal;
      into =
        { host, deployment, ... }:
        ms:
        let
          sys = host.channel.nixpkgs.lib.nixosSystem {
            system = host.system.name;
            modules = ms;
          };
        in
        {
          nixosConfigurations.${host.name} = sys;
          colmena.${host.name} = {
            imports = ms;
            deployment = {
              targetHost = deployment.address;
              inherit (deployment) tags;
            };
          }; # channel
          age-manifest.${host.name} = lib.attrNames sys.config.age.secrets; # channel
          deploy.nodes.${host.name} = {
            hostname = deployment.address;
            sshUser = deployment.user;
          };
        };
    }
    {
      at = ren.kinds.guest; # forwards to the physical host
      into =
        { guest, ... }:
        ms: {
          nixos.microvm.vms.${guest.name} = {
            pkgs = pkgsOf guest;
            config.imports = ms;
          };
        };
    }
  ];

}
