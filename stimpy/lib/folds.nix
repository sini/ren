stimpy: {
  folds =
    let
      inherit (stimpy) lib merge;
      mk = name: fold: {
        __ren = {
          ref = "fold";
          inherit name;
        };
        inherit fold;
      };
    in
    {
      list = mk "list" (_: vs: vs);
      set = mk "set" (_: vs: lib.unique vs);
      attrs = mk "attrs" (loc: vs: if vs == [ ] then { } else merge.mergeStrict loc vs);
      one = mk "one" (
        loc: vs:
        let
          n = builtins.length vs;
        in
        if n == 1 then
          builtins.head vs
        else
          throw "ren: ${lib.concatStringsSep "." loc}: fold one got ${toString n}"
      );
    };
}
