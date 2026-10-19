# Ren instance identity = gen-schema `id_hash` (fleet-ren.md `same a b`).
# One minted gen-schema kind per is-root; its only identity key is `name`, so the
# hash covers is-root kind mark + instance name and never forces lazy field values.
{ gen }:
roots:
let
  schema = gen.schema.evalSchema { } [
    {
      config.schema = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = { };
        }) roots
      );
    }
  ];
in
root: name: gen.schema.identityHashForKind schema.${root} { inherit name; }
