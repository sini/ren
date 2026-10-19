# pipeline: kinds -> instances -> scopes -> activation -> landing/emissions/pools -> classes -> outputs.
# Every stage is lazy; pools, emissions and outputs are one fixpoint (renArgs reads pools and outputs).
{ gen }:
let
  K = import ./kinds.nix { inherit gen; };
  S = import ./scopes.nix { inherit gen; };
  P = import ./predicates.nix { inherit gen; };
  A = import ./activation.nix {
    inherit gen;
    predicates = P;
  };
  C = import ./content.nix { inherit gen; };
  L = import ./classes.nix { inherit gen; };
  out = import ./pipeline-out.nix;
in
{
  lib,
  names,
  decl,
}:
let
  inherit (builtins) filter;
  kinds = K.mkKinds {
    inherit lib;
    decls = decl.kinds or { };
  };
  instances = K.mkInstances {
    inherit lib kinds;
    decls = lib.genAttrs names (k: decl.${k} or { });
  };
  sc = S.mkScopes { inherit kinds instances; };
  ctx = {
    data = id: sc.scopes.${id};
    parent = sc.parentOf;
    inherit (sc) children ancestors;
    siblings = id: lib.remove id (sc.children (sc.parentOf id));
  };
  classes = decl.classes or { };
  channels = decl.channels or { };
  aspects = import ./pipeline-aspects.nix decl;
  act = A.mkActivation { inherit aspects ctx; };
  test = p: id: P.test ctx { activeAt = act.active; } p id;
  # ruling: a branch with `at` absent/null matches every scope, like a channel's default (fleet-ren.md:102)
  matches = b: id: (b.at or null) == null || test b.at id;
  branchAt =
    c: id:
    let
      m = filter (b: matches b id) (L.branches classes.${c});
    in
    if builtins.length m > 1 then
      throw "ren: class `${c}`: more than one branch matches ${id}"
    else if m == [ ] then
      null
    else
      builtins.head m;
  # ruling: content's `is P x` tests x's scope on the current path (fleet-ren.md:113), so it is bound per scope id
  renArgs = import ./pipeline-args.nix {
    inherit
      lib
      P
      sc
      pools
      act
      ctx
      ;
  };
  inherit (o) pools;
  args = {
    inherit
      lib
      L
      C
      sc
      test
      channels
      classes
      branchAt
      renArgs
      act
      aspects
      ;
  };
  strata = import ./strata.nix (args // { inherit matches; });
  o = out (args // { inherit strata; });
in
{
  inherit
    kinds
    instances
    aspects
    test
    ;
  inherit (o) outputs;
}
