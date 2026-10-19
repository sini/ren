{ lib }:
let
  merge = import ./merge.nix { inherit lib; };
  folds = import ./folds.nix { inherit lib merge; };
  pred = import ./pred.nix { inherit lib; };
  view = import ./view.nix { inherit lib; };
  evalFleet = import ./eval.nix {
    inherit
      lib
      merge
      folds
      pred
      view
      ;
  };
in
{
  mkFlake = inputs: module: (evalFleet inputs module).outputs;
  inherit evalFleet;
}
