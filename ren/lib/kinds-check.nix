# instance validation for kinds.nix: fields via A2 mergeDefinitions, name uniqueness per is-root family.
ren: {
  kindsCheck =
    { rootOf, idOf, ... }:
    {
      mkInstances =
        {
          lib,
          kinds,
          decls,
        }:
        let
          idHash = idOf (map (k: rootOf kinds k lib) (builtins.attrNames kinds));
          mkOne =
            k: n: given:
            let
              fields = kinds.${k}.fields;
              where = "ren: ${k}.${n}";
              unknown = builtins.attrNames (removeAttrs given (builtins.attrNames fields));
              clash = builtins.filter (
                k2: k2 != k && decls.${k2} ? ${n} && rootOf kinds k2 lib == rootOf kinds k lib
              ) (builtins.attrNames decls);
              field =
                f: fv:
                let
                  isOpt = fv._type or null == "option";
                  type = if isOpt then fv.type else fv;
                  defs =
                    if given ? ${f} then
                      [
                        {
                          file = where;
                          value = given.${f};
                        }
                      ]
                    else if isOpt && fv ? default then
                      [
                        {
                          file = where;
                          value = fv.default;
                        }
                      ]
                    else
                      throw "${where}: missing field `${f}`";
                in
                (lib.modules.mergeDefinitions [ k n f ] type defs).mergedValue;
              g = kinds.${k}.guard;
              inst = {
                __ren = "instance";
                kind = k;
                name = n;
                __id = "${rootOf kinds k lib}:${n}";
                id_hash = idHash (rootOf kinds k lib) n;
                __guard = g;
              }
              // builtins.mapAttrs field fields;
            in
            # scope ids are "kind:name/kind:name" (scopes-parent.nix parses them): a name with `/` or `:` cannot exist.
            if builtins.match ".*[/:].*" n != null then
              throw "ren: instance name `${n}` (kind `${k}`) must not contain `/` or `:`"
            else if unknown != [ ] then
              throw "${where}: unknown field `${builtins.head unknown}`"
            else if clash != [ ] then
              throw "ren: name `${n}` used by both kind `${k}` and kind `${builtins.head clash}`"
            else if g != null && !(g.args inst) then
              throw "ren: instance `${k}.${n}` violates its kind guard"
            else
              inst;
        in
        builtins.mapAttrs (k: builtins.mapAttrs (mkOne k)) decls;
    };
}
