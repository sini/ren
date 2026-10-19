# Local gen roster: lazy fixpoint over members via the `inputs` bag; src throws => nothing can fetch.
{ genRoot ? /home/vic/hk/gen }:
let
  names = [ "algebra" "aspects" "assemble" "bind" "class" "delivery" "dispatch" "graph" "identity" "inspect" "link" "memo" "merge" "prelude" "product" "program" "rules" "schema" "scope" "select" "settings" "types" "view" ];
  noFetch = segs: throw "gen-entry: fetch attempted for ${toString segs}";
  # leaf members take `{ }` only: pass just the formals each declares
  call = p: let f = import p; in
    f (builtins.intersectAttrs (builtins.functionArgs f) { inputs = members; src = noFetch; });
  members = builtins.listToAttrs (map (n: { name = "gen-${n}"; value = call (genRoot + "/gen-${n}"); }) names);
in
members // { gen = call (genRoot + "/gen"); }
