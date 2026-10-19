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
      hasSuffix =
        suf: s:
        builtins.stringLength s >= builtins.stringLength suf
        &&
          builtins.substring (
            builtins.stringLength s - builtins.stringLength suf
          ) (builtins.stringLength suf) s == suf;
      # shortcut: sep escapes only `\` and `.`; extend when a fleet splits on other regex metacharacters.
      splitString =
        sep: s:
        builtins.filter builtins.isString (
          builtins.split (builtins.replaceStrings [ "\\" "." ] [ "\\\\" "\\." ] sep) s
        );
      recursiveUpdate =
        l: r:
        builtins.zipAttrsWith
          (
            _: vs:
            if
              builtins.length vs == 2
              && builtins.isAttrs (builtins.head vs)
              && builtins.isAttrs (builtins.elemAt vs 1)
            then
              ren.genLib.recursiveUpdate (builtins.head vs) (builtins.elemAt vs 1)
            else
              builtins.elemAt vs (builtins.length vs - 1)
          )
          [
            l
            r
          ];
      removeSuffix =
        suf: s:
        if ren.genLib.hasSuffix suf s then
          builtins.substring 0 (builtins.stringLength s - builtins.stringLength suf) s
        else
          s;
    };
}
