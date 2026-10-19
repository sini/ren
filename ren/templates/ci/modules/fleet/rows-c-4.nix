{ ren, lib }:
let
  inherit (import ../../fixtures/fleet-args.nix { inherit ren lib; }) out variant;
in
{
  fleet-rows-c = {
    # per-branch stratum 3: the within-host branch forwards into nixos, so it must not read nixosConfigurations
    test-stratum3-within-host-reads-outputs = {
      expr =
        (variant (
          { ren, ... }:
          r:
          r
          // {
            classes = r.classes // {
              homeManager = [
                {
                  at = ren.lib.and [
                    ren.kinds.user
                    (ren.lib.within ren.kinds.host)
                  ];
                  into =
                    { user, outputs, ... }:
                    ms: {
                      nixos.home-manager.users.${user.name}.imports = ms ++ [
                        { osHosts = builtins.attrNames outputs.nixosConfigurations; }
                      ];
                    };
                }
              ]
              ++ builtins.tail r.classes.homeManager;
            };
          }
        )).nixosConfigurations.lb.config.home-manager.users.alice.osHosts;
      expectedError.type = "ThrownError";
      expectedError.msg = "stratum 3";
    };

    # anyOf: Ren exports anyOf, never `any`
    test-anyof-no-any = {
      expr = [
        (ren ? anyOf)
        (ren ? any)
      ];
      expected = [
        true
        false
      ];
    };

    # channel into
    test-channel-into-packages = {
      expr = lib.mapAttrs (_: p: p.hello) out.packages;
      expected = {
        x86_64-linux = "hello-x86_64-linux";
        aarch64-linux = "hello-aarch64-linux";
        aarch64-darwin = "hello-aarch64-darwin";
      };
    };
    test-channel-into-collector = {
      expr = [
        (builtins.attrNames (removeAttrs out.colmenaHive [ "meta" ]))
        (builtins.attrNames out.ageManifest)
      ];
      expected = [
        [
          "lb"
          "stage"
          "web-1"
          "web-2"
        ]
        [
          "lb"
          "stage"
          "web-1"
          "web-2"
        ]
      ];
    };
  };
}
