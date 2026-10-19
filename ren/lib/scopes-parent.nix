# gen `parseParent` for Ren path ids: "a/b/c" -> "a/b", root "a" -> null. Without it gen-scope's
# genericResolve walks all roots for every spawned node (measured: 97% of `just test fleet`, 14.5s vs 3.2s).
# instance names with `/` or `:` are refused at declaration (kinds-check.nix), so this parse is total.
ren: {
  scopesParent =
    id:
    let
      m = builtins.match "(.*)/[^/]*" id;
    in
    if m == null then null else builtins.head m;
}
