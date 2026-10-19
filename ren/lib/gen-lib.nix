# genLib: the `lib` fleet modules and Ren's pipeline see, built from Gen only (no nixpkgs).
ren:
let
  inherit (ren) gen;
in
{
  genLib =
    builtins
    // gen.prelude
    // gen.merge
    // {
      # gen-types enum takes a name first (gen-types checkers.nix:1023).
      types = gen.merge.types // {
        enum = vs: gen.merge.types.enum "enum" vs;
      };
      concatMapStrings = f: xs: builtins.concatStringsSep "" (map f xs);
      evalModules =
        { modules }:
        gen.merge.evalModuleTree {
          specialArgs = {
            lib = ren.genLib;
          };
        } modules;
      # type.merge bridges nested trees (gen-merge modules.nix:3988); kinds-check passes plain defs, no mk* at top level.
      modules.mergeDefinitions = loc: type: defs: {
        mergedValue = type.merge loc defs;
      };
      reverseList =
        xs: builtins.genList (i: builtins.elemAt xs (builtins.length xs - i - 1)) (builtins.length xs);
      remove = x: builtins.filter (y: y != x);
    };
}
