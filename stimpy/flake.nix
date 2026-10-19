{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  outputs =
    { nixpkgs, ... }:
    let
      fleet = {
        path = ./templates/fleet;
        description = "Ren fleet demo";
      };
    in
    {
      lib = import ./default.nix { inherit (nixpkgs) lib; };
      templates = {
        inherit fleet;
        default = fleet;
      };
    };
}
