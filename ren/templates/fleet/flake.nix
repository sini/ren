{
  inputs = {
    ren.url = "github:vic/ren";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.url = "github:nix-community/nix-on-droid";
    terranix.url = "github:terranix/terranix";
    colmena.url = "github:zhaofengli/colmena";
    agenix.url = "github:ryantm/agenix";
    microvm.url = "github:microvm-nix/microvm.nix";
    impermanence.url = "github:nix-community/impermanence";
  };
  outputs = inputs: inputs.ren.lib.load { inherit (inputs.nixpkgs) lib; } inputs (import ./fleet.nix);
}
