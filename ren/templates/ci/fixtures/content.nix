# Shared fixtures for the content tests (not a test module).
{ ren, ... }:
rec {
  c = ren.content;
  fails = x: !(builtins.tryEval (builtins.deepSeq x null)).success;
  em = path: value: {
    inherit path value;
    scope = path;
  };
  lnd = c.landing {
    keyKind =
      k:
      if k == "nixos" then
        "class"
      else if k == "env" then
        "channel"
      else
        null;
    classMatches = _: s: s == "h";
    channelMatches = _: s: s != "x";
  };
  asp = k: {
    name = "a";
    content.${k} = 1;
  };
}
