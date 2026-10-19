# Shared fixtures for the predicates tests (not a test module).
{ ren, lib }:
rec {
  p = ren.predicates;
  inst = n: {
    __ren = "instance";
    __id = "k:${n}";
    id_hash = "k:${n}";
  };
  sc = id: kinds: i: {
    inherit kinds;
    instance = i;
    __ren = "scope";
    __scope = id;
  };
  nodes = {
    root = sc "root" [ "root" ] (inst "r");
    env = sc "env" [ "env" ] (inst "e");
    host = sc "host" [ "host" "machine" ] (inst "h");
    user = sc "user" [ "user" ] (inst "u");
    host2 = sc "host2" [ "host" "machine" ] (inst "h2");
  };
  par = {
    root = null;
    env = "root";
    host = "env";
    user = "host";
    host2 = "env";
  };
  kids = {
    root = [ "env" ];
    env = [
      "host"
      "host2"
    ];
    host = [ "user" ];
    user = [ ];
    host2 = [ ];
  };
  anc = id: if par.${id} == null then [ ] else [ par.${id} ] ++ anc par.${id};
  ctx = {
    data = id: nodes.${id};
    parent = id: par.${id};
    children = id: kids.${id};
    ancestors = anc;
    siblings = id: if par.${id} == null then [ ] else lib.remove id kids.${par.${id}};
  };
  kind = n: {
    __ren = "kind";
    name = n;
  };
  t = p.test ctx { };
  hostK = kind "host";
}
