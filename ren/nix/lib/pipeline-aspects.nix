# aspects: normalise declared aspects; non-meta keys are content.
decl:
let
  meta = [
    "at"
    "includes"
    "excludes"
  ];
in
builtins.mapAttrs (name: a: {
  __ren = "aspect";
  inherit name;
  at = a.at or null;
  includes = a.includes or [ ];
  excludes = a.excludes or [ ];
  content = removeAttrs a meta;
}) (decl.aspects or { })
