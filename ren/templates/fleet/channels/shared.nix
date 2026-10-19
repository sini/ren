# CHANNELS: persisted, flake-inputs and meta data.
{
  ren,
  ...
}:
let
  inherit (ren.lib) and anyOf within;
  inherit (ren.lib.fold) set attrs;
in
{
  persist = {
    fold = set;
    # ruling C4 (vic/fleet-ren.md): only scopes with a `host` binding emit; mac/phone/home users have none.
    at = anyOf [
      ren.kinds.host
      (and [
        ren.kinds.user
        (within ren.kinds.host)
      ])
    ];
    to = e: e.host;
  };
  # no `at`: any scope emits
  flake-inputs = {
    fold = attrs;
    to = _: ren.fleet.main;
    into = { ... }: inputs': { flake-file.inputs = inputs'; };
  };
  meta = {
    fold = set;
    to = e: e;
  };

}
