{ ren, lib }:
let
  inherit (import ../../fixtures/fleet.nix { inherit ren lib; })
    laptop
    machines
    devicesOf
    aliceScopes
    ;
in
{
  fleet-rows-a = {
    # standalone home: git + syncthing, no ssh-agent
    test-standalone-home = {
      expr = {
        git = laptop.programs.git.enable;
        syncthing = laptop.services.syncthing.enable;
        ssh-agent = laptop.services ? ssh-agent;
      };
      expected = {
        git = true;
        syncthing = true;
        ssh-agent = false;
      };
    };

    # host-qualified: htop for alice on web-1 only, never bob
    test-host-qualified-htop = {
      expr = lib.mapAttrs (
        _: c: lib.mapAttrs (_: u: u.programs.htop.enable or false) c.home-manager.users
      ) machines;
      expected = {
        lb.alice = false;
        web-1.alice = true;
        web-2.alice = false;
        stage = {
          alice = false;
          bob = false;
        };
        ci = {
          alice = false;
          bob = false;
        };
        studio = {
          alice = false;
          bob = false;
        };
      };
    };

    # substitute: web-2 "ren" only, others "managed by ren"
    test-substitute-motd = {
      expr = lib.mapAttrs (_: c: c.users.motd) machines;
      expected = {
        lb = "managed by ren";
        web-1 = "managed by ren";
        web-2 = "ren";
        stage = "managed by ren";
        ci = "managed by ren";
        studio = "managed by ren";
      };
    };

    # contains: docker on stage and ci only
    test-has-docker = {
      expr = lib.mapAttrs (_: c: c.virtualisation.docker.enable or false) (
        lib.removeAttrs machines [ "studio" ]
      );
      expected = {
        lb = false;
        web-1 = false;
        web-2 = false;
        stage = true;
        ci = true;
      };
    };

    # parent: alice's devices = every alice scope's parent minus this one
    test-parent-syncthing-devices = {
      expr = (lib.mapAttrs (_: devicesOf "alice") machines) // {
        alice-laptop = lib.attrNames laptop.services.syncthing.settings.devices;
      };
      expected = lib.genAttrs [
        "alice-laptop"
        "ci"
        "lb"
        "stage"
        "studio"
        "web-1"
        "web-2"
      ] (h: lib.remove h aliceScopes);
    };
  };
}
