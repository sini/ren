# KINDS: below = child kinds; spawns.<child> = s: instances (gen-scope mkKind, parent side).
{
  ren,
  h,
  ...
}:
let
  inherit (h)
    settingsT
    inEnv
    maybe
    t
    opt
    ;
in
{
  fleet = {
    below = [
      ren.kinds.system
      ren.kinds.environment
      ren.kinds.home
      ren.kinds.replica
    ];
  }; # spawns default: every instance
  system = { };
  channel = {
    nixpkgs = t.raw;
    home-manager = t.raw;
    darwin = opt t.raw null;
  };
  group = {
    members = opt (t.listOf ren.kinds.group) [ ];
  };

  environment = {
    below = [
      ren.kinds.host
      ren.kinds.mac
      ren.kinds.phone
    ];
    spawns = {
      host = inEnv ren.host;
      mac = inEnv ren.mac;
      phone = inEnv ren.phone;
    };
    grants = t.listOf ren.kinds.group;
    edge = opt t.bool false;
    inherits = maybe ren.kinds.environment;
    settings = opt settingsT { };
  };

}
