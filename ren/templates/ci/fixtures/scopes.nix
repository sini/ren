# Shared fixtures for the scopes tests (not a test module).
{ ren, lib }:
rec {
  inst =
    kind: name: extra:
    {
      __ren = "instance";
      __id = "${kind}:${name}";
      inherit kind name;
    }
    // extra;
  kinds = {
    fleet.below = [ "environment" ];
    environment = {
      below = [ "host" ];
      spawns.host = s: lib.filterAttrs (_: h: h.environment.name == s.name) instances.host;
    };
    host.below = [
      "user"
      "guest"
    ];
    guest = {
      is = "host";
      below = [ "user" ];
      spawns.user = _: instances.user;
    };
    user = { };
  };
  stage = inst "host" "stage" { environment = instances.environment.staging; };
  instances = {
    fleet.main = inst "fleet" "main" { };
    environment = {
      staging = inst "environment" "staging" { };
      prod = inst "environment" "prod" { };
    };
    host = {
      inherit stage;
      web = inst "host" "web" { environment = instances.environment.prod; };
    };
    guest.ci = inst "guest" "ci" { on = stage; };
    user.alice = inst "user" "alice" { };
  };
  guestSpawn = kinds // {
    host = kinds.host // {
      spawns.guest = s: lib.filterAttrs (_: g: g.on.name == s.name) instances.guest;
    };
  };
  r = ren.scopes.mkScopes {
    kinds = guestSpawn;
    inherit instances;
  };
  ci = "fleet:main/environment:staging/host:stage/guest:ci/user:alice";
  twice = ren.scopes.mkScopes {
    kinds = {
      r.below = [ "a" ];
      a.below = [ "a" ];
    };
    instances = {
      r.y = inst "r" "y" { };
      a.x = inst "a" "x" { };
    };
  };
}
