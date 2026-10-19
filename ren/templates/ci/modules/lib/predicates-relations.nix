{ ren, lib }:
let
  inherit (import ../../fixtures/predicates.nix { inherit ren lib; })
    p
    inst
    ctx
    t
    hostK
    ;
in
{
  predicates = {
    test-has = {
      expr = [
        (t (p.has (inst "u")) "host")
        (t (p.has (inst "u")) "host2")
      ];
      expected = [
        true
        false
      ];
    };
    test-within-strict = {
      expr = [
        (t (p.within hostK) "user")
        (t (p.within hostK) "host")
      ];
      expected = [
        true
        false
      ];
    };
    test-when = {
      expr = t (p.when (b: builtins.elem "user" b.kinds)) "user";
      expected = true;
    };
    test-aspect = {
      expr = p.test ctx { activeAt = n: id: n == "a" && id == "user"; } {
        __ren = "aspect";
        name = "a";
      } "user";
      expected = true;
    };
    test-isAt-nearest = {
      expr = p.isAt ctx { } hostK (inst "h") "user";
      expected = true;
    };
    test-isAt-missing = {
      expr = p.isAt ctx { } hostK (inst "zzz") "user";
      expectedError.type = "ThrownError";
    };
    test-same = {
      expr = [
        (p.same (inst "a") (inst "a"))
        (p.same (inst "a") (inst "b"))
      ];
      expected = [
        true
        false
      ];
    };
  };
}
