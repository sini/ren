{
  gen ? import (builtins.fetchTarball {
    url = "https://github.com/sini/gen/archive/bcbc5ca579614643fa3433034fd0248b0d551f65.tar.gz";
    sha256 = "1hlrc843zvzk6w59x32k9c7g7hl4gvw2wcjp6sg03gx0204gskrz";
  }) { },
}:
let
  # nest pattern: each lib/*.nix is `ren: { <name> = …; }` and sees the merged set.
  # file arg stays plain `ren:` — destructuring it would force the fixpoint.
  files = builtins.filter (f: builtins.match ".*\\.nix" f != null) (
    builtins.attrNames (builtins.readDir ./lib)
  );
  ren = builtins.foldl' (acc: f: acc // import (./lib + "/${f}") ren) { inherit gen; } files;
in
removeAttrs ren [ "gen" ]
