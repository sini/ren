{ ren, lib }:
let
  inherit (import ../../fixtures/mkflake.nix { inherit ren lib; }) run;
  # `is P x` from content args: x's scope on the current path (fleet-ren.md:113)
  shellOf =
    pick:
    run (ren: {
      isTest = {
        at = ren.kinds.box;
        sys =
          { is, box, ... }:
          {
            users.p.shell = lib.mkForce (
              if is (ren.lib.when (s: s.box.name == "b3")) (pick ren box) then "zsh" else "bash"
            );
          };
      };
    });
in
{
  fleet-is = {
    test-is-instance-on-path = {
      expr = lib.mapAttrs (_: s: s.users.p.shell) (shellOf (_: box: box)).systems;
      expected = {
        b1 = "bash";
        b2 = "bash";
        b3 = "zsh";
      };
    };
    test-is-no-scope-on-path = {
      expr = (shellOf (ren: _: ren.box.b3)).systems.b1.users.p.shell;
      expectedError.type = "ThrownError";
      expectedError.msg = "has no scope on path";
    };
    test-lib-is-instance-named-error = {
      expr =
        (run (ren: {
          isTest = {
            at = ren.kinds.box;
            sys = { box, ... }: lib.optionalAttrs (ren.lib.is ren.kinds.box box) { motd = lib.mkForce "x"; };
          };
        })).systems.b1.motd;
      expectedError.type = "ThrownError";
      expectedError.msg = "needs the scope-local `is`";
    };
  };
}
