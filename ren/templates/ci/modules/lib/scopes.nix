{ ren, lib }:
let
  inherit (import ../../fixtures/scopes.nix { inherit ren lib; })
    inst
    r
    ci
    twice
    ;
in
{
  scopes = {
    test-order = {
      expr = r.order;
      expected = [
        "fleet:main"
        "fleet:main/environment:prod"
        "fleet:main/environment:prod/host:web"
        "fleet:main/environment:prod/host:web/user:alice"
        "fleet:main/environment:staging"
        "fleet:main/environment:staging/host:stage"
        "fleet:main/environment:staging/host:stage/user:alice"
        "fleet:main/environment:staging/host:stage/guest:ci"
        ci
      ];
    };
    test-guest-only-under-stage = {
      expr = r.children "fleet:main/environment:prod/host:web";
      expected = [ "fleet:main/environment:prod/host:web/user:alice" ];
    };
    test-bindings = {
      expr =
        let
          s = r.scopes.${ci};
        in
        [
          s.host.name
          s.guest.name
          s.environment.name
          s.parent.name
        ];
      expected = [
        "ci"
        "ci"
        "staging"
        "ci"
      ];
    };
    test-ancestors = {
      expr = r.ancestors ci;
      expected = [
        "fleet:main/environment:staging/host:stage/guest:ci"
        "fleet:main/environment:staging/host:stage"
        "fleet:main/environment:staging"
        "fleet:main"
      ];
    };
    test-kinds-chain = {
      expr = r.scopes.${ci}.kinds;
      expected = [
        "user"
      ];
    };
    test-kinds-is = {
      expr = r.scopes."fleet:main/environment:staging/host:stage/guest:ci".kinds;
      expected = [
        "guest"
        "host"
      ];
    };
    test-parentOf-root = {
      expr = r.parentOf "fleet:main";
      expected = null;
    };
    test-spawns-not-below = {
      expr =
        (ren.scopes.mkScopes {
          kinds = {
            r = {
              below = [ "a" ];
              spawns.b = _: { };
            };
            a = { };
          };
          instances.r.y = inst "r" "y" { };
        }).order;
      expectedError.type = "ThrownError";
      expectedError.msg = "ren: kind `r` spawns `b` not in below";
    };
    test-twice-on-path = {
      expr = twice.order;
      expectedError.type = "ThrownError";
      expectedError.msg = "ren: instance a:x twice on path r:y/a:x/a:x";
    };
  };
}
