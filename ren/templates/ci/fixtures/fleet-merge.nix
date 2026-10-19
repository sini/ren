# Fixtures for the fleet rows tests that merge a variant into the template fleet.
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
  # variant: the template fleet with `f ren decl.ren` merged into its declaration
  variant =
    f:
    load (
      args:
      let
        r = fleet args;
      in
      r
      // {
        decl = r.decl // {
          ren = lib.recursiveUpdate r.decl.ren (f args.ren);
        };
      }
    );
  n = out.nixosConfigurations;
  ciCfg =
    (stubs.stubEval stubs.nixpkgs.legacyPackages.x86_64-linux [ n.stage.config.microvm.vms.ci.config ])
    .config;
  nOverlays = c: builtins.length c.config.nixpkgs.overlays;
  noAero = u: !(u ? programs.aerospace);
}
