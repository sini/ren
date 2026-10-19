# Packages: each system emits flake packages.
{ ren, inputs, ... }:
{
  ren.channels.packages = {
    fold = ren.lib.fold.attrs;
    at = ren.kinds.system;
    to = e: e;
    into = { system, ... }: pkgs': { packages.${system.name} = pkgs'; };
  };

  ren.aspects.tools = {
    at = ren.kinds.system;
    packages = { system, ... }: { inherit (inputs.nixpkgs.legacyPackages.${system.name}) hello; };
  };
}
