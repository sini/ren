# alice: ops (admin through the closure), has a phone and a standalone home, uses htop on web-1.
{ ren, ... }:
let
  inherit (ren.lib) and within;
in
{
  ren.user.alice = {
    groups = [ ren.group.ops ];
    phone = true;
  }; # admin through the closure

  ren.home.alice-laptop = {
    user = ren.user.alice;
    channel = ren.channel.edge;
    system = ren.system.x86_64-linux;
  };

  ren.aspects.htop = {
    at = and [
      ren.user.alice
      (within ren.host.web-1)
    ];
    homeManager.programs.htop.enable = true;
  };
}
