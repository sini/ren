{
  inputs.gen.url = "github:sini/gen/bcbc5ca579614643fa3433034fd0248b0d551f65";

  outputs = inputs: {
    lib = import ./nix/lib { gen = import inputs.gen.outPath { }; };
    templates.fleet = {
      path = ./templates/fleet;
      description = "Ren fleet";
    };
  };
}
