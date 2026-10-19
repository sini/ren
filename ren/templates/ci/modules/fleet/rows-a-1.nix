{ ren, lib }:
let
  inherit (import ../../fixtures/fleet.nix { inherit ren lib; })
    out
    nixos
    cfg
    ciVm
    ci
    studio
    devicesOf
    ;
in
{
  fleet-rows-a = {
    # fold = one
    test-fold-one-deploy-node = {
      expr = out.deploy.nodes;
      expected = {
        lb = {
          hostname = "10.0.1.1";
          sshUser = "deploy";
        };
        web-1 = {
          hostname = "10.0.1.10";
          sshUser = "deploy";
        };
        web-2 = {
          hostname = "10.0.1.11";
          sshUser = "deploy";
        };
        stage = {
          hostname = "10.0.2.10";
          sshUser = "deploy";
        };
      };
    };

    # fold = list order: web-1 then web-2, nothing else
    test-fold-list-haproxy-order = {
      expr = (cfg "lb").services.haproxy.config;
      expected = "  server 10.0.1.10 10.0.1.10:80 check\n  server 10.0.1.11 10.0.1.11:80 check\n";
    };

    # guest channel: ci gets stable pkgs though stage is edge
    test-guest-channel-stable = {
      expr = ciVm.pkgs.channel;
      expected = "stable";
    };

    # chained forward: bob's ci home lives in ci's nixos inside stage, not in stage's own users
    test-chained-forward = {
      expr = {
        ciBob = devicesOf "bob" ci;
        stageBob = devicesOf "bob" (cfg "stage");
      };
      expected = {
        ciBob = [
          "stage"
          "studio"
        ];
        stageBob = [
          "ci"
          "studio"
        ];
      };
    };

    # darwin + os
    test-darwin-os = {
      expr = {
        host = studio.networking.hostName;
        motd = studio.users.motd;
        git = studio.programs.git.enable;
        dock = studio.system.defaults.dock.autohide;
        homes = lib.attrNames studio.home-manager.users;
        inNixos = nixos ? studio;
        inColmena = out.colmenaHive ? studio;
        kernel = studio ? boot;
        impermanence = studio ? environment;
      };
      expected = {
        host = "studio";
        motd = "managed by ren";
        git = true;
        dock = true;
        homes = [
          "alice"
          "bob"
        ];
        inNixos = false;
        inColmena = false;
        kernel = false;
        impermanence = false;
      };
    };

  };
}
