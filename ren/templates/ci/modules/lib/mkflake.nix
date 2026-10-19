{ ren, lib }:
let
  inherit (import ../../fixtures/mkflake.nix { inherit ren lib; })
    run
    out
    pick
    inputs
    ;
  # mini fleet: class `probe` at box lists its args; class `any` has no `at`
  probe =
    { ren, ... }:
    {
      ren.classes.probe = {
        at = ren.kinds.box;
        into = args: _: { probed = builtins.attrNames args; };
      };
      ren.classes.any.into = args: _: { seen.${args.name} = true; };
      ren.kinds = {
        root.below = [ ren.kinds.box ];
        box = { };
      };
      ren.root.r = { };
      ren.box.b = { };
    };
  loaded = ren.mkFlake inputs probe;
in
{
  mkflake = {
    test-args-no-internal-keys = {
      expr = builtins.filter (
        k:
        builtins.elem k [
          "__ren"
          "__scope"
          "instance"
          "kinds"
          "kind"
        ]
      ) loaded.probed;
      expected = [ ];
    };
    test-class-without-at-matches-every-scope = {
      expr = loaded.seen;
      expected = {
        r = true;
        b = true;
      };
    };
    test-fleet = {
      expr = lib.mapAttrs (_: pick) out.systems;
      expected = {
        b1 = {
          peers = [ "b2" ];
          motd = "hi";
          users.p.shell = "fish";
        };
        b2 = {
          peers = [ "b1" ];
          motd = "hi";
          users.p.shell = "fish";
        };
        b3 = {
          peers = [ ];
          motd = "q";
          users.p.shell = "fish";
        };
      };
    };
    test-unknown-aspect-key = {
      expr =
        (run (ren: {
          bad = {
            at = ren.kinds.root;
            nope = 1;
          };
        })).systems;
      expectedError.type = "ThrownError";
      expectedError.msg = "key `nope` is neither class nor channel";
    };
  };
}
