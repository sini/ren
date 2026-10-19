inputs:
let
  lib = inputs.nixpkgs.lib;
  ren = import ../.. { gen = import inputs.gen.outPath { }; };
  dir = ./modules;
  walk =
    path:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        if type == "directory" then
          walk (path + "/${name}")
        else if lib.hasSuffix ".nix" name then
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
