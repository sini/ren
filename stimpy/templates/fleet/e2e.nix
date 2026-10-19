# Lock-walk: builds `inputs` for the fleet from ./flake.lock without git-tracked getFlake.
# The impl (the root input whose lock node is a local path placeholder) is the local tree ../..;
# it is also exposed as `inputs.impl`, so tests never name it.
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  rootInputs = lock.nodes.root.inputs;
  implName = builtins.head (
    builtins.filter (n: (lock.nodes.${rootInputs.${n}}.locked.type or "") == "path") (
      builtins.attrNames rootInputs
    )
  );
  impl = {
    lib = import ../.. { };
  };
  # `follows` refs are lists of input names, walked from root
  nodeOf =
    ref:
    if builtins.isList ref then
      builtins.foldl' (n: i: nodeOf lock.nodes.${n}.inputs.${i}) "root" ref
    else
      ref;
  built =
    builtins.mapAttrs
      (
        name: n:
        let
          src = builtins.fetchTree n.locked;
          inputs = builtins.mapAttrs (_: ref: built.${nodeOf ref}) (n.inputs or { });
          outs = (import (src + "/flake.nix")).outputs (inputs // { self = self; });
          self = outs // src // { sourceInfo = src; };
        in
        if n.flake or true then self else src
      )
      (
        removeAttrs lock.nodes [
          "root"
          rootInputs.${implName}
        ]
      )
    // {
      ${rootInputs.${implName}} = impl;
    };
in
builtins.mapAttrs (_: ref: built.${nodeOf ref}) rootInputs // { inherit impl; }
