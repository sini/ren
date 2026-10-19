# KINDS: below = child kinds; spawns.<child> = s: instances (gen-scope mkKind, parent side). Split under ./kinds.
args: import ./kinds/containers.nix args // import ./kinds/machines.nix args
