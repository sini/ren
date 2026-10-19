{ ren, lib }:
let
  inherit (import ../../fixtures/fleet-args.nix { inherit ren lib; }) variant addAspects hmOn;
in
{
  fleet-rows-c = {
    # no guest in a guest: stage still hosts ci only, x never becomes a scope
    test-no-guest-in-guest = {
      expr =
        let
          o = variant (
            { ren, ... }:
            r:
            r
            // {
              guest = r.guest // {
                x = r.guest.ci // {
                  on = ren.guest.ci;
                };
              };
            }
          );
        in
        builtins.attrNames o.nixosConfigurations.stage.config.microvm.vms;
      expected = [ "ci" ];
    };

    # identity without scopes: `same` on scope-less groups; groups never spawn
    test-identity-same-groups = {
      expr =
        (addAspects (ren: {
          probe = {
            at = ren.fleet.main;
            flake-inputs = { ... }: {
              probe = [
                (ren.lib.same ren.group.ops ren.group.ops)
                (ren.lib.same ren.group.ops ren.group.admin)
              ];
            };
          };
        })).flake-file.inputs.probe;
      expected = [
        true
        false
      ];
    };
    test-identity-groups-never-spawn = {
      expr =
        (addAspects (ren: {
          probe = {
            at = ren.kinds.group;
            flake-inputs = { ... }: { grp.url = "x"; };
          };
        })).flake-file.inputs
          ? grp;
      expected = false;
    };

    # is P x on the path: tray follows the user's own parent
    test-is-on-path-stage-tray = {
      expr = map (u: (hmOn "stage").${u}.services.syncthing.tray.enable) [
        "alice"
        "bob"
      ];
      expected = [
        true
        true
      ];
    };
    test-is-on-path-lb-no-tray = {
      expr = (hmOn "lb").alice.services.syncthing.tray.enable;
      expected = false;
    };

  };
}
