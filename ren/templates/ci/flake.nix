{
  inputs = {
    with-inputs.url = "github:denful/with-inputs";
    with-inputs.flake = false;
    gen.url = "github:sini/gen/bcbc5ca579614643fa3433034fd0248b0d551f65";
    gen.flake = false;
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = _: { };
}
