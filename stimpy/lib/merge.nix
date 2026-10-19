stimpy: {
  merge =
    let
      inherit (stimpy) lib;
      mergeStrict =
        loc: defs:
        let
          head = builtins.head defs;
          mergeable = d: builtins.isAttrs d && !(lib.isDerivation d) && !(d ? _type);
          err = throw "ren: conflict at ${lib.concatStringsSep "." loc}";
        in
        if builtins.length defs == 1 then
          head
        else if builtins.all mergeable defs then
          lib.zipAttrsWith (n: vs: mergeStrict (loc ++ [ n ]) vs) defs
        else if builtins.any builtins.isFunction defs then
          err
        else if builtins.all (d: d == head) defs then
          head
        else
          err;
    in
    {
      inherit mergeStrict;
    };
}
