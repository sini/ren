{
  r,
  ev,
  ...
}:
let
  i = import ./_ids.nix;
  thrown = expr: {
    inherit expr;
    expectedError.type = "ThrownError";
  };
  # force every scope id and the whole landed/emitted/pools skeleton
  force = x: builtins.deepSeq (builtins.attrNames x.scopes) (builtins.attrNames x.pools);
  mod = f: ev f;
in
{
  # control: the unmodified fleet evaluates
  test-control-fleet-evaluates = {
    expr = builtins.isList (force r);
    expected = true;
  };
  # row: name uniqueness - ren.host.ci and ren.guest.ci both evaluating
  test-error-host-ci-duplicates-guest-ci = thrown (
    force (
      mod (
        { ren, ... }:
        {
          ren.host.ci = {
            environment = ren.environment.prod;
            channel = ren.channel.stable;
            system = ren.system.x86_64-linux;
            addr = "10.0.1.99";
          };
        }
      )
    )
  );
  # row: content-function rule (C5) - a bare `final: prev:` emission is not content
  # pools are lazy (design: fold on read), so force the elements, not just the spine
  test-error-bare-overlay-function = thrown (
    (x: builtins.deepSeq x (builtins.length x))
      (mod (
        { ren, ... }:
        {
          ren.aspects.bad-overlay = {
            at = ren.fleet.main;
            overlays = final: prev: { };
          };
        }
      )).pools.overlays.${i.lb}
  );
  # row: flake-file - two features giving agenix different urls
  test-error-agenix-url-conflict = thrown (
    (mod (
      { ren, ... }:
      {
        ren.aspects.agenix-fork = {
          at = ren.host.lb;
          flake-inputs = { ... }: { agenix.url = "github:other/agenix"; };
        };
      }
    )).pools."flake-inputs".${i.root}
  );
  # row: parent-side spawns - spawns.user on a kind whose `below` lacks user
  test-error-spawns-user-without-below = thrown (
    force (
      mod (
        { ren, ... }:
        {
          ren.kinds.system.spawns.user = _: { };
        }
      )
    )
  );
  # row: no guest in a guest - guest on a guest makes no scope (see scopes.nix); the module still evaluates
  # UNTESTABLE-T1: output merge (two scopes writing different nixosConfigurations.lb) - needs forced system values
  # UNTESTABLE-T1: unstratified omit/unless cycle - no template fixture; lib tests cover it
  # UNTESTABLE-T1: Ren exporting `any` (anyOf tombstone) - lib tests
}
