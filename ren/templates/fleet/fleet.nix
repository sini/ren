# The fleet of fleet-ren.md (## Fleet), split by section; this file holds the shared helpers.
{
  ren,
  inputs,
  lib,
}:
let
  t = lib.types;
  opt = type: default: lib.mkOption { inherit type default; };
  h = rec {
    inherit t opt;
    maybe = type: opt (t.nullOr type) null;
    first = lib.findFirst (v: v != null) null; # nearest non-null wins
    pkgsOf = m: m.channel.nixpkgs.legacyPackages.${m.system.name}; # m: anything with channel + system
    inEnv = xs: s: lib.filterAttrs (_: x: ren.lib.same x.environment s.environment) xs;
    metal = ren.lib.and [
      ren.kinds.host
      (ren.lib.not ren.kinds.guest)
    ]; # physical nixos hosts
    settingsT = t.submodule {
      options.kernel.channel = maybe (
        t.enum [
          "lts"
          "latest"
        ]
      );
    };
    # nested groups
    closure =
      gs:
      map (x: x.g) (
        lib.genericClosure {
          startSet = map (g: {
            key = g.name;
            inherit g;
          }) gs;
          operator =
            x:
            map (p: {
              key = p.name;
              g = p;
            }) (lib.filter (p: lib.any (ren.lib.same x.g) p.members) (lib.attrValues ren.group));
        }
      );
    usersOn = s: lib.filterAttrs (_: granted s) ren.user;
    granted = s: u: lib.any (g: lib.any (ren.lib.same g) s.environment.grants) (closure u.groups);
  };
  args = {
    inherit
      ren
      inputs
      lib
      h
      ;
  };
in
ren.lib.mkFlake inputs {
  ren = {
    classes = import ./classes.nix args;
    kinds = import ./kinds.nix args;
    channels = import ./channels.nix args;
    aspects = import ./aspects.nix args;
  }
  // import ./instances.nix args;
}
