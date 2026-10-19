# Shared fixtures for the kinds tests (not a test module).
{ ren, lib }:
rec {
  t = lib.types;
  opt = type: default: lib.mkOption { inherit type default; };
  settingsT = t.submodule {
    options.kernel.channel = opt (t.nullOr t.str) null;
  };
  kinds = ren.kinds.mkKinds {
    inherit lib;
    decls = {
      machine = {
        addr = t.str;
        settings = opt settingsT { };
      };
      host = {
        is = kinds.machine;
        below = [ kinds.user ];
      };
      guest = {
        is = kinds.host;
        on = kinds.host;
      };
      user = { };
      group = {
        members = opt (t.listOf kinds.group) [ ];
      };
      db.zone = t.str;
      region.zone = t.str;
      replica =
        { db, region }:
        ren.when (s: s.db.zone == s.region.zone) { };
    };
  };
  mk =
    decls:
    ren.kinds.mkInstances {
      inherit lib kinds decls;
    };
  boom = x: (builtins.tryEval (builtins.deepSeq x null)).success;
  ok = mk {
    host.h = {
      addr = "1";
    };
    group = {
      a = { };
      b.members = [ ok.group.a ];
    };
  };
  anInst = ok.host.h;
  replicas =
    z:
    let
      i = mk {
        db.d.zone = "eu";
        region.g.zone = z;
      };
    in
    mk {
      replica.r = {
        db = i.db.d;
        region = i.region.g;
      };
    };
}
