{ ren, lib }:
let
  inherit (import ../../fixtures/activation.nix { inherit ren lib; })
    p
    h
    u
    act
    motd
    q
    nginx
    httpPort
    na
    nb
    ;
in
{
  activation = {
    test-at-kind = {
      expr = map (n: (act { inherit motd; }) "motd" (h n)) [
        "web-1"
        "web-2"
        "db"
      ];
      expected = [
        true
        true
        true
      ];
    };
    test-included-only-subtree = {
      expr = [
        (q "motd-short" (h "web-2"))
        (q "motd-short" (u "web-2"))
        (q "motd-short" (h "web-1"))
      ];
      expected = [
        true
        true
        false
      ];
    };
    test-exclude-beats-include = {
      expr = [
        (q "motd" (h "web-2"))
        (q "motd" (u "web-2"))
        (q "motd" (h "web-1"))
      ];
      expected = [
        false
        false
        true
      ];
    };
    test-aspect-ref-in-at = {
      expr =
        map
          (
            (act {
              inherit nginx;
              "http-port" = httpPort;
            })
              "http-port"
          )
          [
            (h "web-1")
            (h "db")
          ];
      expected = [
        true
        false
      ];
    };
    test-negative-cycle = {
      expr =
        (act {
          a = na // {
            at = p.not nb;
          };
          b = nb // {
            at = p.not na;
          };
        })
          "a"
          (h "db");
      expectedError.type = "ThrownError";
      expectedError.msg = "ren: aspects not stratified: .*";
    };
  };
}
