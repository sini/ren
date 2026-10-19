inputs:
let
  ren = import ../.. { gen = import inputs.gen.outPath { }; };
  lib = ren.genLib;
  dir = ./modules;
  walk =
    path:
    builtins.concatLists (
      lib.mapAttrsToList (
        name: type:
        if type == "directory" then
          walk (path + "/${name}")
        else if builtins.match ".*\.nix" name != null then
          [ (path + "/${name}") ]
        else
          [ ]
      ) (builtins.readDir path)
    );
  mods = map (f: import f { inherit ren lib; }) (walk dir);
in
{
  tests = lib.foldl' (acc: m: lib.recursiveUpdate acc m) { } mods;
}
