# gen node for Ren instance `inst` under parent decls `p` ({ } at a root), rank `r` among siblings.
# decls carry the Ren scope; `seen` enforces once-per-path; `rank` rebuilds Ren's preorder.
isChain: p: r: inst:
let
  inherit (builtins)
    attrNames
    elem
    filter
    listToAttrs
    ;
  nv = name: value: { inherit name value; };
  parent = p.scope or null;
  pid = if parent == null then null else parent.__scope;
  id = (if pid == null then "" else pid + "/") + "${inst.kind}:${inst.name}";
  fields = filter (f: (inst.${f}.__ren or null) == "instance") (attrNames inst);
  bindings =
    (p.bindings or { })
    // listToAttrs (map (f: nv f inst.${f}) fields)
    // listToAttrs (map (k: nv k inst) (isChain inst.kind));
  scope = bindings // {
    __ren = "scope";
    __scope = id;
    inherit (inst) name kind;
    instance = inst;
    kinds = isChain inst.kind;
    inherit parent;
  };
in
if elem inst.__id (p.seen or [ ]) then
  throw "ren: instance ${inst.__id} twice on path ${id}"
else
  nv id {
    decls = {
      inherit scope bindings;
      seen = (p.seen or [ ]) ++ [ inst.__id ];
      rank = (p.rank or [ ]) ++ [ r ];
    };
  }
