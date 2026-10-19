# synthetic vocabulary shared by stratum tests (no fleet words)
{ lib, stimpy }:
let
  t = lib.types;
  base =
    { ren, ... }:
    let
      inZone = xs: s: lib.filterAttrs (_: x: ren.lib.same x.zone s.zone) xs;
    in
    {
      ren.kinds = {
        world.below = [ ren.kinds.zone ];
        zone = {
          below = [
            ren.kinds.node
            ren.kinds.vm
          ];
          spawns = {
            node = inZone ren.node;
            vm = inZone ren.vm;
          };
        };
        node = {
          zone = ren.kinds.zone;
          below = [ ren.kinds.person ];
        };
        vm = {
          is = ren.kinds.node;
          below = [ ren.kinds.person ];
        };
        person = { };
      };
      ren.world.w = { };
      ren.zone.z1 = { };
      ren.zone.z2 = { };
      ren.node.n1.zone = ren.zone.z1;
      ren.node.n2.zone = ren.zone.z1;
      ren.vm.v1.zone = ren.zone.z2;
      ren.person.p = { };
    };
in
{
  run = ms: stimpy.evalFleet { } { imports = [ base ] ++ ms; };
  # realize collected modules cheaply
  realize =
    ms:
    (lib.evalModules {
      modules = ms ++ [ { options.out = lib.mkOption { type = t.attrs; }; } ];
    }).config.out;
  err.type = "ThrownError";
  w = "world:w";
  z1 = "world:w/zone:z1";
  z2 = "world:w/zone:z2";
  n1 = "world:w/zone:z1/node:n1";
  n2 = "world:w/zone:z1/node:n2";
  v1 = "world:w/zone:z2/vm:v1";
  p1 = "world:w/zone:z1/node:n1/person:p";
  p2 = "world:w/zone:z1/node:n2/person:p";
  pv = "world:w/zone:z2/vm:v1/person:p";
}
