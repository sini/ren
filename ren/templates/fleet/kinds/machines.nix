# KINDS: machines, users and data kinds.
{
  ren,
  lib,
  h,
  ...
}:
let
  inherit (ren.lib) when same;
  inherit (h)
    settingsT
    usersOn
    t
    opt
    ;
in
{
  # abstract: no `below` lists it
  machine = {
    environment = ren.kinds.environment;
    channel = ren.kinds.channel;
    system = ren.kinds.system;
    addr = t.str;
    settings = opt settingsT { };
  };
  host = {
    is = ren.kinds.machine;
    below = [
      ren.kinds.user
      ren.kinds.guest
    ];
    spawns = {
      user = usersOn;
      guest = s: lib.filterAttrs (_: g: same g.on s.host) ren.guest;
    };
  };
  mac = {
    is = ren.kinds.machine;
    below = [ ren.kinds.user ];
    spawns.user = usersOn;
  };
  # declares its own `below`: no guest in a guest
  guest = {
    is = ren.kinds.host;
    below = [ ren.kinds.user ];
    spawns.user = usersOn;
    on = ren.kinds.host;
  };

  phone = {
    below = [ ren.kinds.user ];
    spawns.user = _: lib.filterAttrs (_: u: u.phone) ren.user;
    environment = ren.kinds.environment;
    channel = ren.kinds.channel;
    system = ren.kinds.system;
  };
  # standalone
  home = {
    below = [ ren.kinds.user ];
    spawns.user = s: { ${s.home.user.name} = s.home.user; };
    user = ren.kinds.user;
    channel = ren.kinds.channel;
    system = ren.kinds.system;
  };

  # each parent says how it spawns users
  user = {
    groups = t.listOf ren.kinds.group;
    phone = opt t.bool false;
  };

  db.zone = t.str;
  region.zone = t.str;
  replica = { db, region }: when (s: s.db.zone == s.region.zone) { };
}
