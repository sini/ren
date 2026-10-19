# Public surface: predicate combinators, fold, version. (`fold` = channel folds, folds.nix.)
ren: {
  inherit (ren.predicates)
    and
    anyOf
    not
    when
    within
    has
    is
    same
    ;
  fold = ren.folds;
  version = "0";
}
