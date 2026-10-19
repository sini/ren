{ lib, stimpy }:
let
  inherit (stimpy) merge folds;
  m = merge.mergeStrict [ ];
  thrown = expr: {
    inherit expr;
    expectedError.type = "ThrownError";
  };
  drv = {
    type = "derivation";
    outPath = "/a";
    drvPath = "/a";
    x = y: y;
  };
in
{
  test-merge-one-def-unforced = {
    expr = builtins.isList [ (m [ (throw "no") ]) ];
    expected = true;
  };
  test-merge-recursive = {
    expr = m [
      { a.b = 1; }
      { a.c = 2; }
    ];
    expected = {
      a = {
        b = 1;
        c = 2;
      };
    };
  };
  test-merge-equal-leaves = {
    expr = m [
      { x = 1; }
      { x = 1; }
    ];
    expected = {
      x = 1;
    };
  };
  test-merge-conflict-leaf = thrown (m [
    { x = 1; }
    { x = 2; }
  ]);
  test-merge-function-leaf-conflict = thrown (m [
    { f = x: x; }
    { f = x: x; }
  ]);
  test-merge-single-function-leaf = {
    expr =
      (m [
        { f = x: x; }
        { g = 1; }
      ]).f
        3;
    expected = 3;
  };
  test-merge-derivation-not-recursed = {
    expr =
      (m [
        { d = drv; }
        { d = drv; }
      ]).d.outPath;
    expected = "/a";
  };
  test-merge-type-equal = {
    expr =
      (m [
        {
          o = {
            _type = "override";
            v = 1;
          };
        }
        {
          o = {
            _type = "override";
            v = 1;
          };
        }
      ]).o.v;
    expected = 1;
  };
  test-merge-type-differ = thrown (m [
    {
      o = {
        _type = "override";
        v = 1;
      };
    }
    {
      o = {
        _type = "override";
        v = 2;
      };
    }
  ]);
  test-merge-attrnames-lazy = {
    expr = builtins.attrNames (m [
      { a = throw "x"; }
      { b = 1; }
    ]);
    expected = [
      "a"
      "b"
    ];
  };
  test-fold-list = {
    expr = folds.list.fold [ ] [ 3 1 2 ];
    expected = [
      3
      1
      2
    ];
  };
  test-fold-set = {
    expr = folds.set.fold [ ] [ 1 2 1 3 ];
    expected = [
      1
      2
      3
    ];
  };
  test-fold-attrs-empty = {
    expr = folds.attrs.fold [ ] [ ];
    expected = { };
  };
  test-fold-attrs-merge = {
    expr =
      folds.attrs.fold
        [ ]
        [
          { a = 1; }
          { b = 2; }
        ];
    expected = {
      a = 1;
      b = 2;
    };
  };
  test-fold-one = {
    expr = folds.one.fold [ ] [ 5 ];
    expected = 5;
  };
  test-fold-one-empty = thrown (folds.one.fold [ "k" ] [ ]);
  test-fold-one-two = thrown (folds.one.fold [ "k" ] [ 1 2 ]);
  test-fold-ref = {
    expr = lib.mapAttrsToList (_: f: f.__ren.ref) folds;
    expected = [
      "fold"
      "fold"
      "fold"
      "fold"
    ];
  };
}
