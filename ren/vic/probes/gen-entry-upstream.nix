# Upstream gen hub (latest github:sini/gen); needs network on first fetch, then cached.
let f = builtins.getFlake "github:sini/gen"; in
{ flake = f; roster = f.lib; }
