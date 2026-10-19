{ ren, lib }:
let
  inherit (import ../../fixtures/fleet-merge.nix { inherit ren lib; })
    out
    variant
    n
    ciCfg
    noAero
    ;
in
{
  fleet-rows-b = {
    test-hm-platforms-studio = {
      expr = lib.mapAttrs (
        _: u: u.programs.aerospace.enable
      ) out.darwinConfigurations.studio.config.home-manager.users;
      expected = {
        alice = true;
        bob = true;
      };
    };
    test-hm-platforms-not-linux = {
      expr =
        lib.all noAero (
          lib.concatMap (c: lib.attrValues c.config.home-manager.users) (lib.attrValues n)
          ++ lib.attrValues ciCfg.home-manager.users
        )
        && noAero out.homeConfigurations.alice-laptop.config;
      expected = true;
    };
    test-meta-emission = {
      expr = out.colmenaHive.stage.deployment.tags;
      expected = [ "web" ];
    };
    test-flake-file = {
      expr = {
        inherit (out) flake-file;
        beside = out ? nixosConfigurations;
      };
      expected = {
        flake-file.inputs = {
          agenix.url = "github:ryantm/agenix";
          microvm.url = "github:microvm-nix/microvm.nix";
        };
        beside = true;
      };
    };
    test-flake-file-url-conflict = {
      expr =
        (variant (ren: {
          aspects.other-agenix = {
            at = ren.fleet.main;
            flake-inputs = { ... }: { agenix.url = "github:fork/agenix"; };
          };
        })).flake-file;
      expectedError.type = "ThrownError";
      expectedError.msg = "conflict at `agenix.url`";
    };
    test-recursive-attrs-deploy = {
      expr = builtins.attrNames out.deploy.nodes;
      expected = [
        "lb"
        "stage"
        "web-1"
        "web-2"
      ];
    };
    test-recursive-attrs-colmena = {
      expr = builtins.attrNames (removeAttrs out.colmenaHive [ "meta" ]);
      expected = [
        "lb"
        "stage"
        "web-1"
        "web-2"
      ];
    };
    test-recursive-attrs-agenix = {
      expr =
        (variant (ren: {
          aspects.agenix-follows = {
            at = ren.fleet.main;
            flake-inputs =
              { ... }:
              {
                agenix.url = "github:ryantm/agenix";
                agenix.inputs.nixpkgs.follows = "nixpkgs";
              };
          };
        })).flake-file.inputs.agenix;
      expected = {
        url = "github:ryantm/agenix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };
  };
}
