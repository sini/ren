# Channel folds: { __ren = "fold"; name; apply = channelName: emissions: value; }
# emissions = [ { path = "<scope id>"; value; } ] in arbitrary order.
{ gen }:
let
  byPath = emissions: builtins.sort (a: b: a.path < b.path) emissions;
  values = emissions: map (e: e.value) (byPath emissions);
  mk = name: apply: {
    __ren = "fold";
    inherit name apply;
  };
  isPlain = v: builtins.isAttrs v && !(v ? type && v.type == "derivation") && !(v ? _type);
  # glue: gen-scope folds has no dedup set fold (folds.nix:426)
  dedup = builtins.foldl' (acc: v: if builtins.elem v acc then acc else acc ++ [ v ]) [ ];
  # glue: gen-scope mergeAttrs is shallow and refuses any shared sub-key; Ren needs recursion + equal leaves.
  conflict =
    c: p: throw "ren: channel `${c}` fold attrs: conflict at `${builtins.concatStringsSep "." p}`";
  # key present on one side only is taken as-is: never forced, never descended.
  merge =
    c: p: a: b:
    a
    // builtins.mapAttrs (
      k: bv:
      if !(a ? ${k}) then
        bv
      else if isPlain a.${k} && isPlain bv then
        merge c (p ++ [ k ]) a.${k} bv
      else if !(isPlain a.${k}) && !(isPlain bv) && a.${k} == bv then
        bv
      else
        conflict c (p ++ [ k ])
    ) b;
  mergeAll =
    c: vs:
    builtins.foldl' (
      acc: v:
      if builtins.isAttrs v then
        merge c [ ] acc v
      else
        throw "ren: channel `${c}` fold attrs: non-attrs emission"
    ) { } vs;
in
{
  list = mk "list" (c: emissions: gen.scope.folds.list c (values emissions));
  set = mk "set" (_: emissions: dedup (values emissions));
  attrs = mk "attrs" (c: emissions: mergeAll c (values emissions));
  one = mk "one" (c: emissions: gen.scope.folds.one c (values emissions));
}
