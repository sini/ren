{ lib, stimpy }:
{
  activation = import ./activation.nix { inherit lib stimpy; };
  collect = import ./collect.nix { inherit lib stimpy; };
  content = import ./content.nix { inherit lib stimpy; };
  folds = import ./folds.nix { inherit lib stimpy; };
  pred = import ./pred.nix { inherit lib stimpy; };
  scopes = import ./scopes.nix { inherit lib stimpy; };
  smoke = import ./smoke.nix { inherit lib stimpy; };
  view = import ./view.nix { inherit lib stimpy; };
}
