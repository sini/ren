# Fixtures for the fleet rows tests that add aspects or inspect scoped configs.
{ ren, lib }:
let
  base = import ./fleet.nix { inherit ren lib; };
  inherit (base)
    stubs
    fleet
    load
    out
    ;
in
{
  inherit
    stubs
    fleet
    load
    out
    ;
}
// rec {
  # variant fleet: f args decl.ren -> decl.ren (lazy in args.ren: load's pass 1 has only ren.lib)
  variant =
    f:
    load (
      args:
      let
        x = fleet args;
      in
      x
      // {
        decl = x.decl // {
          ren = f args x.decl.ren;
        };
      }
    );
  addAspects =
    as:
    variant (
      args: r:
      r
      // {
        aspects = r.aspects // as args.ren;
      }
    );
  hmUsers = sys: builtins.attrNames sys.config.home-manager.users;
  hmOn = h: out.nixosConfigurations.${h}.config.home-manager.users;
  # ci lives as a deferred module in stage: realize it with the stub's freeform shape
  ciCfg =
    (lib.evalModules {
      modules = [
        out.nixosConfigurations.stage.config.microvm.vms.ci.config
        {
          freeformType = lib.types.lazyAttrsOf lib.types.anything;
          options.home-manager.users = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule { freeformType = lib.types.lazyAttrsOf lib.types.anything; }
            );
            default = { };
          };
          config._module.args.pkgs = stubs.nixpkgs.legacyPackages.x86_64-linux;
        }
      ];
    }).config;
  errs = v: !(builtins.tryEval (builtins.deepSeq v v)).success;
}
