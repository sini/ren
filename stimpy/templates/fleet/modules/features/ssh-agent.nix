# ssh-agent: for every user on a machine.
{ ren, ... }:
{
  ren.aspects.ssh-agent = {
    at = ren.lib.and [
      ren.kinds.user
      (ren.lib.within ren.kinds.machine)
    ];
    homeManager.services.ssh-agent.enable = true;
  };
}
