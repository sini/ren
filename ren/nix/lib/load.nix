# load: ties the knot between a fleet declaration and the `ren` that declaration reads.
# ruling: a fleet file is `{ ren, inputs, lib }: ren.lib.mkFlake inputs { ren.kinds = ...; ren.<kind>.<n> = ...; }`
#   (fleet-ren.md:140); `load { inherit lib; } inputs file` returns the flake outputs.
# Nix attrset keys are strict, so `ren`'s keys cannot come from a decl that reads `ren`:
#   pass 1 calls the file with only `ren.lib` and reads the kind names; pass 2 gets the full `ren`.
# ruling: `ren.<kind>` exists for every declared kind (empty when it has no instances) (fleet-ren.md:95).
{ gen, surface }:
let
  build = import ./pipeline.nix { inherit gen; };
  mkFlake = inputs: decl: {
    __ren = "flake";
    inherit inputs decl;
  };
  renLib = surface // {
    inherit mkFlake;
  };
in
{
  inherit mkFlake;
  load =
    { lib }:
    inputs: file:
    let
      call = ren: (file { inherit ren inputs lib; }).decl.ren;
      names = builtins.attrNames ((call { lib = renLib; }).kinds or { });
      d = call ren;
      p = build {
        inherit lib names;
        decl = d;
      };
      ren = {
        # ruling: `is P x` on a scope tests P at that scope; content gets `parent` as a scope (fleet-ren.md:467)
        # ruling: an instance x needs the current path (fleet-ren.md:113): renLib.is throws, use content's `{ is, ... }:`
        lib = renLib // {
          is = P: x: if (x.__ren or null) == "scope" then p.test P x.__scope else renLib.is P x;
        };
        inherit (p) kinds aspects;
      }
      // p.instances;
    in
    p.outputs;
}
