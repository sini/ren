{ gen }:
let
  predicates = import ./predicates.nix { inherit gen; };
  fold = import ./folds.nix { inherit gen; };
  surface = {
    inherit (predicates)
      and
      anyOf
      not
      when
      within
      has
      is
      same
      ;
    inherit fold;
  };
  loader = import ./load.nix { inherit gen surface; };
in
surface
// {
  version = "0";
  inherit predicates;
  inherit (loader) load mkFlake;
  kinds = import ./kinds.nix { inherit gen; };
  activation = import ./activation.nix { inherit gen predicates; };
  scopes = import ./scopes.nix { inherit gen; };
  content = import ./content.nix { inherit gen; };
  classes = import ./classes.nix { inherit gen; };
}
