# Lock-walk: builds `inputs` for fleet.nix from ./flake.lock without git-tracked getFlake.
# stimpy lock node is a local path placeholder; e2e uses ../..
# The `stimpy` node is the local tree (the lock's path node is only a placeholder).
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  stimpy = {
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
          "stimpy"
        ]
      )
    // {
      stimpy = stimpy;
    };
in
builtins.mapAttrs (_: ref: built.${nodeOf ref}) lock.nodes.root.inputs
