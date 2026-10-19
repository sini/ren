{ ren, lib }:
let
  out = ren.load { inherit lib; } (import ../../fleet-stubs.nix { inherit lib; }) (
    import ../../../fleet/fleet.nix
  );
in
{
  fleet = {
    test-nixos-hosts = {
      expr = builtins.attrNames out.nixosConfigurations;
      expected = [
        "lb"
        "stage"
        "web-1"
        "web-2"
      ];
    };
    test-darwin-studio = {
      expr = out.darwinConfigurations ? studio;
      expected = true;
    };
    test-home-alice-laptop = {
      expr = out.homeConfigurations ? alice-laptop;
      expected = true;
    };
    test-packages-hello = {
      expr = out.packages.x86_64-linux.hello;
      expected = "hello-x86_64-linux";
    };
  };
}
