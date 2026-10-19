{ ren, lib }:
let
  inherit (import ../../fixtures/predicates.nix { inherit ren lib; })
    p
    inst
    kind
    t
    hostK
    ;
in
{
  predicates = {
    test-kind = {
      expr = [
        (t hostK "host")
        (t hostK "user")
      ];
      expected = [
        true
        false
      ];
    };
    test-subkind = {
      expr = t (kind "machine") "host2";
      expected = true;
    };
    test-instance = {
      expr = [
        (t (inst "h") "host")
        (t (inst "h") "host2")
      ];
      expected = [
        true
        false
      ];
    };
    test-and-anyOf-not = {
      expr = [
        (t (p.and [
          hostK
          (inst "h")
        ]) "host")
        (t (p.and [
          hostK
          (inst "h")
        ]) "host2")
        (t (p.anyOf [
          (kind "user")
          (kind "env")
        ]) "env")
        (t (p.not hostK) "host")
      ];
      expected = [
        true
        false
        true
        false
      ];
    };
  };
}
