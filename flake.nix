{
  inputs.gen.url = "github:sini/gen/bcbc5ca579614643fa3433034fd0248b0d551f65";

  outputs =
    inputs:
    (import ./ren/flake.nix).outputs inputs
    // rec {
      templates.default = templates.ren;
      templates.ren = {
        path = ./ren/templates/fleet;
        description = "Ren fleet";
      };
      templates.stimpy = {
        path = ./stimpy/templates/fleet;
        description = "Stimpy fleet";
      };
    };
}
