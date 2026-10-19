# Scope ids: concatStringsSep "/" (map (p: "${p.kind}:${p.name}") path)
rec {
  root = "fleet:main";
  prod = "${root}/environment:prod";
  staging = "${root}/environment:staging";
  lb = "${prod}/host:lb";
  web1 = "${prod}/host:web-1";
  web2 = "${prod}/host:web-2";
  stage = "${staging}/host:stage";
  ci = "${stage}/guest:ci";
  studio = "${staging}/mac:studio";
  pixel = "${staging}/phone:pixel";
  laptop = "${root}/home:alice-laptop";
  replica = "${root}/replica:r1";
  sys = n: "${root}/system:${n}";
  user = parent: n: "${parent}/user:${n}";
  machines = [
    lb
    web1
    web2
    stage
    ci
    studio
  ];
  metals = [
    lb
    web1
    web2
    stage
  ];
}
