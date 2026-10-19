# Aspect activation. Any aspect-graph cycle throws (positive cycles too: no well-foundedness check, relax when needed).
{ gen, predicates }:
let
  inherit (builtins)
    any
    attrNames
    concatMap
    elem
    filter
    head
    throw
    ;
  names = map (a: a.name);
  # [ { ref; neg; } ] aspects named inside a predicate
  refs =
    neg: p:
    if p.__ren == "aspect" then
      [
        {
          ref = p.name;
          inherit neg;
        }
      ]
    else if p.__ren != "pred" then
      [ ]
    else if p.op == "when" then
      [ ]
    else if
      elem p.op [
        "and"
        "anyOf"
      ]
    then
      concatMap (refs neg) p.args
    else
      refs (neg || p.op == "not") p.args;
in
{
  mkActivation =
    { aspects, ctx }:
    let
      ns = attrNames aspects;
      # edges B -> A as { from; to; neg; }
      edgeList = concatMap (
        n:
        let
          a = aspects.${n};
          mk = neg: from: to: { inherit from to neg; };
        in
        map (r: mk r.neg r.ref n) (if a.at == null then [ ] else refs false a.at)
        ++ map (x: mk false n x) (names a.includes)
        ++ map (x: mk true n x) (names a.excludes)
      ) ns;
      topo = gen.graph.topoOrder { } {
        nodes = ns;
        edges = n: map (e: e.to) (filter (e: e.from == n) edgeList);
      };
      bad = filter (c: any (e: e.neg && elem e.from c && elem e.to c) edgeList) topo.cycles;
      show = c: builtins.concatStringsSep " -> " c;
      checked =
        if topo.ok then
          true
        else if bad != [ ] then
          throw "ren: aspects not stratified: ${show (head bad)}"
        else
          throw "ren: aspect cycle: ${show (head topo.cycles)}";

      orSelf = s: [ s ] ++ ctx.ancestors s;
      by =
        field: a: s:
        any (b: elem a (names aspects.${b}.${field}) && any (t: active b t) (orSelf s)) ns;
      direct =
        a: s: aspects.${a}.at != null && predicates.test ctx { activeAt = active; } aspects.${a}.at s;
      active = a: s: checked && !(by "excludes" a s) && (direct a s || by "includes" a s);
    in
    {
      inherit active;
      activeAt = active;
    };
}
