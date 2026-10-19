# Overlays: the fleet emits nixpkgs overlays; every machine reads them (see base).
{ ren, inputs, ... }:
{
  ren.channels.overlays = {
    fold = ren.lib.fold.list;
    at = ren.kinds.fleet;
    to = _: ren.kinds.machine;
  };

  ren.aspects.unstable-overlay = {
    # a function value: wrap it in `{ ... }:`
    at = ren.fleet.main;
    overlays = { ... }: final: prev: {
      inherit (inputs.nixpkgs-unstable.legacyPackages.${prev.system}) helix;
    };
  };
}
