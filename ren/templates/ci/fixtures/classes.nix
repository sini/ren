# Shared fixtures for the classes tests (not a test module).
{ ren, lib }:
rec {
  c = ren.classes;
  ancs = {
    stage = [ ];
    ci = [ "stage" ];
    bob = [
      "ci"
      "stage"
    ];
  };
  mk =
    {
      order ? [
        "bob"
        "ci"
        "stage"
      ],
      cls ? classes,
      anc ? (id: ancs.${id}),
    }:
    c.mkCollect {
      classes = cls;
      channelNames = [ ];
      branchAt =
        n: id:
        let
          m = builtins.filter (b: b.id == id) (c.branches cls.${n});
        in
        if builtins.length m > 1 then
          throw "ren: class `${n}`: 2 branches match ${id}"
        else
          lib.findFirst (_: true) null m;
      scopeOrder = order;
      ancestors = anc;
      renArgsAt = id: { name = id; };
      contentModules = n: id: [ "${n}:${id}" ];
    };
  classes = {
    nixos = [
      {
        id = "stage";
        into = a: ms: { outputs.nixosConfigurations.${a.name} = ms; };
      }
      {
        id = "ci";
        into = a: ms: { nixos.vms.${a.name} = ms; };
      }
    ];
    hm = {
      id = "bob";
      into = _: ms: { nixos.users.bob = ms; };
    };
  };
  refused = x: (builtins.tryEval (builtins.deepSeq x null)).success;
  r = mk { };
}
