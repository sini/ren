# ASPECTS: feature aspects (ports, kernel, persistence, dev tools).
{
  ren,
  inputs,
  h,
  ...
}:
let
  inherit (ren.lib) and anyOf;
  inherit (h) metal first;
in
{
  # an aspect ref = "active here"
  http-port = {
    at = and [
      ren.kinds.host
      ren.aspects.nginx
    ];
    nixos.networking.firewall.allowedTCPPorts = [ 80 ];
  };

  kernel = {
    at = ren.kinds.host;
    nixos =
      {
        host,
        environment,
        pkgs,
        ...
      }:
      let
        k = first [
          host.settings.kernel.channel
          environment.settings.kernel.channel
          (environment.inherits.settings.kernel.channel or null)
          "latest"
        ];
      in
      {
        boot.kernelPackages = if k == "lts" then pkgs.linuxPackages else pkgs.linuxPackages_latest;
      };
  };

  impermanence = {
    at = metal;
    nixos =
      { persist, ... }:
      {
        imports = [ inputs.impermanence.nixosModules.impermanence ];
        environment.persistence."/persist".directories = persist;
      };
  };

  dev = {
    at = anyOf [
      ren.kinds.machine
      ren.kinds.user
    ];
    os.programs.git.enable = true;
    homeManager.programs.git.enable = true;
  };

}
