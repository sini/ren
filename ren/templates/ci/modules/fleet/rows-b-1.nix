{ ren, lib }:
let
  inherit (import ../../fixtures/fleet-merge.nix { inherit ren lib; })
    out
    variant
    n
    ciCfg
    nOverlays
    ;
in
{
  fleet-rows-b = {
    # row impermanence (`set`): stage persists nginx, docker, alice's and bob's syncthing dirs, once each; not ci's docker dir.
    test-impermanence-set = {
      expr = lib.sort (
        a: b: a < b
      ) out.nixosConfigurations.stage.config.environment.persistence."/persist".directories;
      expected = [
        "/home/alice/.local/state/syncthing"
        "/home/bob/.local/state/syncthing"
        "/var/lib/docker"
        "/var/lib/nginx"
      ];
    };
    test-per-system = {
      expr = lib.mapAttrs (_: p: p.hello) out.packages;
      expected = {
        x86_64-linux = "hello-x86_64-linux";
        aarch64-linux = "hello-aarch64-linux";
        aarch64-darwin = "hello-aarch64-darwin";
      };
    };
    # every machine once; ci's own nixos, not stage's, carries it
    test-overlays = {
      expr = (lib.mapAttrs (_: nOverlays) n) // {
        studio = nOverlays out.darwinConfigurations.studio;
        ci = builtins.length ciCfg.nixpkgs.overlays;
      };
      expected = {
        lb = 1;
        web-1 = 1;
        web-2 = 1;
        stage = 1;
        studio = 1;
        ci = 1;
      };
    };
    test-overlays-helix = {
      expr = (builtins.head n.lb.config.nixpkgs.overlays { } { system = "aarch64-linux"; }).helix;
      expected = "helix-aarch64-linux";
    };
    test-name-uniqueness = {
      expr =
        builtins.attrNames
          (variant (ren: {
            host.ci = {
              environment = ren.environment.prod;
              channel = ren.channel.stable;
              system = ren.system.x86_64-linux;
              addr = "10.0.1.2";
            };
          })).nixosConfigurations;
      expectedError.type = "ThrownError";
      expectedError.msg = "name `ci` used by both kind";
    };
    test-output-merge = {
      expr =
        (variant (ren: {
          channels.evil = {
            fold = ren.lib.fold.list;
            at = ren.kinds.host;
            to = e: e;
            into = { host, ... }: _: { nixosConfigurations.lb = host.name; };
          };
          aspects.evil = {
            at = ren.kinds.host;
            evil = { ... }: 1;
          };
        })).nixosConfigurations.lb;
      expectedError.type = "ThrownError";
      expectedError.msg = "conflict at `nixosConfigurations.lb`";
    };
    test-content-function-rule = {
      expr =
        map builtins.typeOf
          (variant (ren: {
            aspects.bare = {
              at = ren.fleet.main;
              overlays = _: _: { };
            };
          })).nixosConfigurations.lb.config.nixpkgs.overlays;
      expectedError.type = "ThrownError";
      expectedError.msg = "ren: bare function emission";
    };
  };
}
