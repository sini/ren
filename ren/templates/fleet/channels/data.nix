# CHANNELS: data (gen-aspects `channel`); at = emitters (default any), to = e: receivers.
{
  ren,
  h,
  ...
}:
let
  inherit (ren.lib)
    and
    not
    when
    same
    ;
  inherit (h) metal;
  inherit (ren.lib.fold)
    list
    set
    attrs
    one
    ;
in
{
  backends = {
    fold = list;
    at = ren.kinds.host;
    to =
      e:
      and [
        ren.kinds.host
        (when (r: same r.host.environment e.host.environment))
        (not e)
        (not ren.aspects.nginx)
      ];
  };
  devices = {
    fold = set;
    at = ren.kinds.user;
    to =
      e:
      and [
        ren.kinds.user
        (when (r: same r.user e.user))
        (not e)
      ];
  };
  records = {
    fold = attrs;
    at = ren.kinds.machine;
    to = _: ren.environment.prod;
  };
  deployment = {
    fold = one;
    at = metal;
    to = e: e;
  };
  scrape = {
    fold = list;
    at = ren.kinds.replica;
    to = _: ren.host.lb;
  };
  overlays = {
    fold = list;
    at = ren.kinds.fleet;
    to = _: ren.kinds.machine;
  };
}
