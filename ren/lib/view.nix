# The fleet is a module (fleet.md:134,579): `options.ren` is the surface, `ren` = `_module.args.ren`.
# One key = one file: kinds/classes/channels/aspects are `lazyAttrsOf raw` (a name in two files = error).
# Instances `ren.<kind>.<name>` are deferred modules, evaluated against the kind's fields.
ren: {
  view =
    let
      declared = [
        "kinds"
        "classes"
        "channels"
        "aspects"
      ];
    in
    {
      inherit declared;
      module =
        { lib, ... }:
        let
          t = lib.types;
        in
        {
          options.ren = lib.mkOption {
            default = { };
            type = t.submodule {
              freeformType = t.lazyAttrsOf (t.lazyAttrsOf t.deferredModule);
              options = lib.genAttrs declared (
                _:
                lib.mkOption {
                  type = t.lazyAttrsOf t.raw;
                  default = { };
                }
              );
            };
          };
        };
      # instance module -> the field values ren's mkInstances validates (kinds-check.nix)
      instance =
        lib: kind: m:
        let
          opt = fv: if fv._type or null == "option" then fv else lib.mkOption { type = fv; };
        in
        removeAttrs
          (lib.evalModules {
            modules = [
              m
              { options = builtins.mapAttrs (_: opt) kind.fields; }
            ];
          }).config
          [ "_module" ];
    };
}
