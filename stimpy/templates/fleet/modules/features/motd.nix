# motd: every machine says "managed by ren"; motd-short is the included-only variant.
{ ren, ... }:
{
  ren.aspects.motd = {
    at = ren.kinds.machine;
    os.environment.etc.motd.text = "managed by ren"; # C10
  };
  ren.aspects.motd-short = {
    os.environment.etc.motd.text = "ren"; # C10
  }; # included only
}
