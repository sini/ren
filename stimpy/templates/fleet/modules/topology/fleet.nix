# Root of the scope tree, and the systems below it.
{ ren, ... }:
{
  # ══ KINDS — below = child kinds; spawns.<child> = s: instances (gen-scope mkKind, parent side) ══
  # A kind no `below` lists has no scopes: data (channel, group, db, region) or abstract (machine).
  ren.kinds.fleet = {
    below = [
      ren.kinds.system
      ren.kinds.environment
      ren.kinds.home
      ren.kinds.replica
    ];
  }; # spawns default: every instance
  ren.kinds.system = { };

  ren.fleet.main = { };
  ren.system.x86_64-linux = { };
  ren.system.aarch64-linux = { };
  ren.system.aarch64-darwin = { };
}
