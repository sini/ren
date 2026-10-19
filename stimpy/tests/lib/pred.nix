{ lib, stimpy }:
let
  p = import ../../lib/pred.nix { inherit lib; };
  mkScope = id: kinds: inst: {
    __ren = {
      ref = "scope";
      kind = lib.head kinds;
      inherit kinds id inst;
    };
  };
  mkInst = id: {
    __ren = {
      ref = "inst";
      kind = "item";
      inherit id;
    };
  };
  r = mkScope "r" [ "root" ] (mkInst "ri");
  b1 = mkScope "b1" [ "box" "container" ] (mkInst "bi1");
  b2 = mkScope "b2" [ "box" "container" ] (mkInst "bi2");
  i1 = mkScope "i1" [ "item" ] (mkInst "ii1");
  parent = {
    b1 = [ r ];
    b2 = [ r ];
    i1 = [
      b1
      r
    ];
    r = [ ];
  };
  kids = {
    r = [
      b1
      b2
    ];
    b1 = [ i1 ];
    b2 = [ ];
    i1 = [ ];
  };
  ctx = {
    activeAt = a: s: a == "A" && s.__ren.id == "b1";
    children = s: kids.${s.__ren.id};
    ancestors = s: parent.${s.__ren.id};
  };
  m = p.match ctx;
  kind = k: {
    __ren = {
      ref = "kind";
      kind = k;
    };
  };
  asp = n: {
    __ren = {
      ref = "aspect";
      name = n;
    };
  };
  box = kind "box";
  t = expr: {
    inherit expr;
    expected = true;
  };
  f = expr: {
    inherit expr;
    expected = false;
  };
  boom = {
    expectedError.type = "ThrownError";
  };
in
{
  test-kind = t (m box b1);
  test-superkind = t (m (kind "container") b2);
  test-kind-no = f (m box i1);
  test-inst = t (m (mkInst "bi1") b1);
  test-inst-no = f (m (mkInst "bi1") b2);
  test-aspect = t (m (asp "A") b1);
  test-aspect-no = f (m (asp "A") b2);
  test-scope-self = t (m b2 b2);
  test-scope-other = f (m b2 b1);
  test-and = t (
    m (p.and [
      box
      (asp "A")
    ]) b1
  );
  test-and-no = f (
    m (p.and [
      box
      (asp "A")
    ]) b2
  );
  test-anyOf = t (
    m (p.anyOf [
      (kind "root")
      box
    ]) b2
  );
  test-not = t (m (p.not box) i1);
  test-and-short-circuit = f (
    m (p.and [
      box
      (p.when (_: throw "x"))
    ]) i1
  );
  test-anyOf-short-circuit = t (
    m (p.anyOf [
      box
      (p.when (_: throw "x"))
    ]) b1
  );
  test-when = t (m (p.when (s: s.__ren.id == "r")) r);
  test-within = t (m (p.within box) i1);
  test-within-proper = f (m (p.within box) b1);
  test-has = t (m (p.has (kind "item")) b1);
  test-has-no = f (m (p.has (kind "item")) b2);
  test-refsOf = {
    expr = p.refsOf (
      p.not (
        p.and [
          (asp "A")
          (p.not (asp "B"))
        ]
      )
    );
    expected = [
      {
        aspect = "A";
        positive = false;
      }
      {
        aspect = "B";
        positive = true;
      }
    ];
  };
  test-refsOf-none = {
    expr = p.refsOf (p.has box);
    expected = [ ];
  };
  test-same = t (p.same b1 b1);
  test-same-no = f (p.same b1 b2);
  test-is = t (p.is ctx box { __ren.scope = b1; });
  test-is-no-scope = boom // {
    expr = p.is ctx box { __ren.id = "x"; };
  };
  test-nonpred = boom // {
    expr = m { } b1;
  };
}
