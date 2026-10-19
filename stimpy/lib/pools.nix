# pools (fleet.md:95-96): pool(c, r) = fold_c [ v(e) | e emits c, r matches `to e` ], path order
{ lib, pred }:
{
  channels,
  st,
  ctx,
  emissions, # channel -> [ { id; v; } ] in scope-path order
}:
let
  inherit (lib) filter elem;
  recv =
    c: e: filter (r: pred.match ctx (channels.${c}.to st.scopes.${e.id}) st.scopes.${r}) st.order;
  tagged = lib.mapAttrs (c: map (e: e // { rs = recv c e; })) emissions;
  poolAt = c: r: channels.${c}.fold.fold [ c r ] (map (e: e.v) (filter (e: elem r e.rs) tagged.${c}));
in
{
  pools = lib.mapAttrs (
    c: es: lib.genAttrs (lib.unique (lib.concatMap (e: e.rs) es)) (poolAt c)
  ) tagged;
  poolsAt = id: lib.mapAttrs (c: _: poolAt c id) channels;
}
