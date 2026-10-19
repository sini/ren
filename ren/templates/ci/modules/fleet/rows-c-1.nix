{ ren, lib }:
let
  inherit (import ../../fixtures/fleet-args.nix { inherit ren lib; })
    out
    variant
    addAspects
    errs
    ;
in
{
  fleet-rows-c = {
    # anywhere: root-scope emissions reach flake-file.inputs
    test-anywhere-inputs = {
      expr = builtins.attrNames out.flake-file.inputs;
      expected = [
        "agenix"
        "microvm"
      ];
    };
    test-anywhere-root-emission = {
      expr =
        (addAspects (ren: {
          root-input = {
            at = ren.fleet.main;
            flake-inputs = { ... }: { rooty.url = "x"; };
          };
        })).flake-file.inputs.rooty.url;
      expected = "x";
    };

    # attrs in into: two features feed packages.<sys>
    test-attrs-into-two-features = {
      expr =
        builtins.attrNames
          (addAspects (ren: {
            tools2 = {
              at = ren.kinds.system;
              packages = { system, ... }: { helix = "helix-${system.name}"; };
            };
          })).packages.x86_64-linux;
      expected = [
        "helix"
        "hello"
      ];
    };
    test-attrs-into-conflict = {
      expr =
        errs
          (addAspects (ren: {
            tools2 = {
              at = ren.kinds.system;
              packages = { ... }: { hello = "other"; };
            };
          })).packages.x86_64-linux.hello;
      expected = true;
    };

    # per-branch stratum 3: the standalone-home branch reads outputs.nixosConfigurations
    test-stratum3-standalone-reads-outputs = {
      expr =
        (variant (
          { ren, ... }:
          r:
          r
          // {
            classes = r.classes // {
              homeManager = lib.init r.classes.homeManager ++ [
                {
                  at = ren.lib.and [
                    ren.kinds.user
                    (ren.lib.within ren.kinds.home)
                  ];
                  into =
                    { home, outputs, ... }:
                    ms: {
                      homeConfigurations.${home.name} = home.channel.home-manager.lib.homeManagerConfiguration {
                        pkgs = home.channel.nixpkgs.legacyPackages.${home.system.name};
                        modules = ms ++ [ { osHost = outputs.nixosConfigurations.lb.config.networking.hostName; } ];
                      };
                    };
                }
              ];
            };
          }
        )).homeConfigurations.alice-laptop.config.osHost;
      expected = "lb";
    };
  };
}
