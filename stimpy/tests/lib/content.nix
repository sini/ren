{ lib, stimpy }:
let
  inherit (import ./vocab.nix { inherit lib stimpy; })
    run
    err
    w
    n1
    n2
    v1
    ;
  # classes: cfg at node; channels over each fold, received at the world
  go =
    extra: aspects:
    run [
      (
        { ren, ... }:
        lib.recursiveUpdate {
          ren.classes.cfg = {
            at = ren.kinds.node;
            into = { node, ... }: ms: { out.${node.name} = ms; };
          };
          ren.channels =
            lib.mapAttrs
              (_: fold: {
                inherit fold;
                at = ren.kinds.node;
                to = _: ren.world.w;
              })
              {
                inherit (ren.lib.fold)
                  list
                  set
                  attrs
                  one
                  ;
              };
          ren.aspects = aspects ren;
        } (extra ren)
      )
    ];
  pool = c: aspects: (go (_: { }) aspects).pools.${c}.${w};
  nodes =
    ren:
    ren.lib.anyOf [
      ren.kinds.node
      ren.kinds.person
    ];
in
{
  test-landed-where-class-lives = {
    expr =
      (go (_: { }) (ren: {
        a.at = nodes ren;
        a.cfg.out.x = 1;
      })).landed.cfg;
    expected = {
      ${n1} = [ "a" ];
      ${n2} = [ "a" ];
      ${v1} = [ "a" ];
    };
  };
  test-lands-nowhere = {
    expr =
      (go (_: { }) (ren: {
        a.at = ren.kinds.person;
        a.cfg = { };
      })).landed;
    expectedError = err;
  };
  test-unknown-key = {
    expr =
      (go (_: { }) (ren: {
        a.at = ren.kinds.node;
        a.bogus = { };
      })).landed;
    expectedError = err;
  };
  test-branches-not-disjoint = {
    expr =
      (go (ren: {
        ren.classes.cfg = [
          { at = ren.kinds.node; }
          { at = ren.kinds.vm; }
        ];
      }) (_: { })).landed;
    expectedError = err;
  };
  test-class-channel-clash = {
    expr = (go (ren: { ren.channels.cfg = ren.channels.list; }) (_: { })).landed;
    expectedError = err;
  };
  test-module-arg-clash = {
    expr = (go (ren: { ren.channels.config = { }; }) (_: { })).landed;
    expectedError = err;
  };
  test-list-path-order = {
    expr = pool "list" (ren: {
      a.at = nodes ren;
      a.list = { node, ... }: node.name;
    });
    expected = [
      "n1"
      "n2"
      "v1"
    ];
  };
  test-set-unique = {
    expr = pool "set" (ren: {
      a.at = ren.kinds.node;
      a.set = { ... }: "s";
    });
    expected = [ "s" ];
  };
  test-attrs-merge = {
    expr = pool "attrs" (ren: {
      a.at = ren.kinds.node;
      a.attrs = { node, ... }: { ${node.name} = 1; };
    });
    expected = {
      n1 = 1;
      n2 = 1;
      v1 = 1;
    };
  };
  test-attrs-conflict = {
    expr = pool "attrs" (ren: {
      a.at = ren.kinds.node;
      a.attrs = { node, ... }: { k = node.name; };
    });
    expectedError = err;
  };
  test-one-ok = {
    expr = pool "one" (ren: {
      a.at = ren.node.n2;
      a.one = { ... }: 7;
    });
    expected = 7;
  };
  test-one-two = {
    expr = pool "one" (ren: {
      a.at = ren.kinds.node;
      a.one = { ... }: 7;
    });
    expectedError = err;
  };
  test-one-zero = {
    expr = pool "list" (ren: {
      a.at = ren.node.n1;
      a.list = { one, ... }: one;
    });
    expectedError = err;
  };
  test-content-fn-bare = {
    expr = pool "list" (ren: {
      a.at = ren.kinds.node;
      a.list = x: x;
    });
    expectedError = err;
  };
}
