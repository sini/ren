# Content values (A6), module wrapping, landing check, channel pools. Inputs abstract.
ren: {
  content =
    let
      xml = f: builtins.toXML f;
      isContentFn = f: builtins.isFunction f && builtins.match ".*<attrspat.*" (xml f) != null;
      hasEllipsis = f: builtins.match ".*<attrspat ellipsis=\"1\".*" (xml f) != null;
      bare = throw "ren: bare function emission; wrap it in `{ ... }:`";
      callContent =
        renArgs: v:
        if !builtins.isFunction v then
          v
        else if !isContentFn v then
          bare
        else if hasEllipsis v then
          v renArgs
        else
          v (builtins.intersectAttrs (builtins.functionArgs v) renArgs);
      # setFunctionArgs without nixpkgs; module args win over ren args only for names ren lacks.
      asModule =
        renArgs: v:
        if !builtins.isFunction v then
          v
        else if !isContentFn v then
          bare
        else
          {
            __functor = _: margs: v (margs // renArgs);
            __functionArgs = removeAttrs (builtins.functionArgs v) (builtins.attrNames renArgs);
          };
      # aspect = { name; content = { key = value; }; }; result = { key = [ scope ids ]; }
      landing =
        {
          keyKind,
          classMatches,
          channelMatches,
        }:
        aspect: scopes:
        builtins.mapAttrs (
          k: _:
          let
            kind = keyKind k;
            ids =
              if kind == "class" then
                builtins.filter (classMatches k) scopes
              else if kind == "channel" then
                builtins.filter (channelMatches k) scopes
              else
                throw "ren: aspect `${aspect.name}`: key `${k}` is neither class nor channel";
          in
          if ids == [ ] then
            throw "ren: aspect `${aspect.name}`: key `${k}` lands in none of its scopes"
          else
            ids
        ) aspect.content;
      mkPools =
        {
          channels,
          emissions,
          receivers,
        }:
        builtins.mapAttrs (
          c: ch: id:
          ch.fold.apply c (builtins.filter (e: builtins.elem id (receivers c e)) emissions.${c})
        ) channels;
    in
    {
      inherit
        callContent
        isContentFn
        mkPools
        landing
        asModule
        ;
    };
}
