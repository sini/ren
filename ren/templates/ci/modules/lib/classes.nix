{ ren, lib }:
let
  inherit (import ../../fixtures/classes.nix { inherit ren lib; })
    c
    mk
    refused
    r
    ;
in
{
  classes = {
    test-chained-forward = {
      expr = r.outputs.outputs.nixosConfigurations.stage;
      expected = [
        "nixos:stage"
        {
          vms.ci = [
            "nixos:ci"
            { users.bob = [ "hm:bob" ]; }
          ];
        }
      ];
    };
    test-output-merge-disjoint = {
      expr =
        (c.mergeOutputs [
          { a.x = 1; }
          { a.y = 2; }
        ]).a;
      expected = {
        x = 1;
        y = 2;
      };
    };
    test-output-conflict = {
      expr = refused (
        c.mergeOutputs [
          { a.x = 1; }
          { a.x = 2; }
        ]
      );
      expected = false;
    };
    test-no-target = {
      expr =
        refused
          (mk {
            order = [ "bob" ];
            anc = _: [ ];
          }).outputs;
      expected = false;
    };
    test-two-branches = {
      expr =
        refused
          (mk {
            cls.nixos = [
              {
                id = "stage";
                into = _: _: { };
              }
              {
                id = "stage";
                into = _: _: { };
              }
            ];
          }).outputs;
      expected = false;
    };
  };
}
