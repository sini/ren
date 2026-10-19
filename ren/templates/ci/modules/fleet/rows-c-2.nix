{ ren, lib }:
let
  inherit (import ../../fixtures/fleet-args.nix { inherit ren lib; })
    out
    variant
    hmUsers
    ciCfg
    errs
    ;
in
{
  fleet-rows-c = {
    # parent-side spawns
    test-spawns-lb = {
      expr = hmUsers out.nixosConfigurations.lb;
      expected = [ "alice" ];
    };
    test-spawns-web = {
      expr = map (h: hmUsers out.nixosConfigurations.${h}) [
        "web-1"
        "web-2"
      ];
      expected = [
        [ "alice" ]
        [ "alice" ]
      ];
    };
    test-spawns-stage = {
      expr = hmUsers out.nixosConfigurations.stage;
      expected = [
        "alice"
        "bob"
      ];
    };
    test-spawns-ci = {
      expr = builtins.attrNames ciCfg.home-manager.users;
      expected = [
        "alice"
        "bob"
      ];
    };
    test-spawns-studio = {
      expr = hmUsers out.darwinConfigurations.studio;
      expected = [
        "alice"
        "bob"
      ];
    };
    test-spawns-alice-pixel-laptop = {
      expr = [
        (out.nixOnDroidConfigurations ? pixel)
        (out.homeConfigurations ? alice-laptop)
      ];
      expected = [
        true
        true
      ];
    };
    test-spawns-below-lacks-user = {
      expr =
        errs
          (variant (
            _: r:
            r
            // {
              kinds = r.kinds // {
                system.spawns.user = _: { };
              };
            }
          )).packages;
      expected = true;
    };

  };
}
