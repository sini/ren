{ ren, lib }:
let
  inherit (import ../../fixtures/content.nix { inherit ren lib; })
    c
    fails
    em
    lnd
    asp
    ;
in
{
  content = {
    test-xml-discriminates = {
      expr = [
        (c.isContentFn ({ ... }: 1))
        (c.isContentFn (_: _: 1))
        (c.isContentFn 1)
      ];
      expected = [
        true
        false
        false
      ];
    };
    test-call-passes-args = {
      expr = [
        (c.callContent { host = 1; } ({ host, ... }: host))
        (c.callContent {
          host = 1;
          user = 2;
        } ({ host }: host))
        (c.callContent { host = 1; } 5)
      ];
      expected = [
        1
        1
        5
      ];
    };
    test-bare-fn-refused = {
      expr = fails (c.callContent { } (_: _: 1));
      expected = true;
    };
    test-asmodule-eval = {
      expr =
        (lib.evalModules {
          modules = [
            { options.x = lib.mkOption { default = null; }; }
            (c.asModule { host = 7; } ({ host, config, ... }: { x = if config ? x then host else 0; }))
          ];
        }).config.x;
      expected = 7;
    };
    test-landing-ok = {
      expr = lnd (asp "nixos") [
        "h"
        "x"
      ];
      expected.nixos = [ "h" ];
    };
    test-landing-neither = {
      expr = fails (lnd (asp "zz") [ "h" ]);
      expected = true;
    };
    test-landing-none = {
      expr = fails (lnd (asp "nixos") [ "x" ]);
      expected = true;
    };
    test-pools-order-and-receivers = {
      expr =
        (c.mkPools
          {
            channels.c.fold = ren.fold.list;
            emissions.c = [
              (em "b" 2)
              (em "a" 1)
              (em "z" 9)
            ];
            receivers = _: e: if e.path == "z" then [ "other" ] else [ "me" ];
          }
          # traversal order, deliberately not string order
          [
            "b"
            "z"
            "a"
          ]
        ).c
          "me";
      expected = [
        2
        1
      ];
    };
  };
}
