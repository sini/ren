# Dev: git on every machine and for every user.
{ ren, ... }:
{
  ren.aspects.dev = {
    at = ren.lib.anyOf [
      ren.kinds.machine
      ren.kinds.user
    ];
    # C8
    os =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.git ];
      };
    homeManager = {
      programs.git.enable = true;
    };
  };
}
