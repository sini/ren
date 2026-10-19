{
  ren,
  lib,
  inputs,
  ...
}:
let
  inherit (ren.lib)
    and
    anyOf
    not
    when
    within
    has
    is
    same
    ;
  inherit (ren.lib.fold)
    list
    set
    attrs
    one
    ;
  t = lib.types;

  opt = type: default: lib.mkOption { inherit type default; };
  maybe = type: opt (t.nullOr type) null;
  first = lib.findFirst (v: v != null) null; # nearest non-null wins

  pkgsOf = m: m.channel.nixpkgs.legacyPackages.${m.system.name}; # m: anything with channel + system
  inEnv = xs: s: lib.filterAttrs (_: x: same x.environment s.environment) xs;

  metal = and [
    ren.kinds.host
    (not ren.kinds.guest)
  ]; # physical nixos hosts

  settingsT = t.submodule {
    options.kernel.channel = maybe (
      t.enum [
        "lts"
        "latest"
      ]
    );
  };

  closure =
    gs:
    map (x: x.g) (
      lib.genericClosure {
        # nested groups
        startSet = map (g: {
          key = g.name;
          inherit g;
        }) gs;
        operator =
          x:
          map (p: {
            key = p.name;
            g = p;
          }) (lib.filter (p: lib.any (same x.g) p.members) (lib.attrValues ren.group));
      }
    );
  usersOn = s: lib.filterAttrs (_: granted s) ren.user;
  granted = s: u: lib.any (g: lib.any (same g) s.environment.grants) (closure u.groups);
in
{

  # ══ CLASSES — module systems (gen-aspects `class`); into returns top-level options ══
  ren.classes = {

    nixos = [
      {
        at = metal;
        into =
          { host, deployment, ... }:
          ms:
          let
            sys = host.channel.nixpkgs.lib.nixosSystem {
              system = host.system.name;
              modules = ms;
            };
          in
          {
            nixosConfigurations.${host.name} = sys;
            colmena.${host.name} = {
              imports = ms;
              deployment = {
                targetHost = deployment.address;
                inherit (deployment) tags;
              };
            }; # channel
            age-manifest.${host.name} = lib.attrNames sys.config.age.secrets; # channel
            deploy.nodes.${host.name} = {
              hostname = deployment.address;
              sshUser = deployment.user;
            };
          };
      }
      {
        at = ren.kinds.guest; # forwards to the physical host
        into = { guest, ... }: ms: {
          nixos.microvm.vms.${guest.name} = {
            pkgs = pkgsOf guest;
            config.imports = ms;
          };
        };
      }
    ];

    darwin = {
      at = ren.kinds.mac;
      into = { mac, ... }: ms: {
        darwinConfigurations.${mac.name} = mac.channel.darwin.lib.darwinSystem {
          system = mac.system.name;
          modules = ms;
        };
      };
    };

    os = [
      # one key, either OS
      {
        at = ren.kinds.host;
        into = { ... }: ms: { nixos.imports = ms; };
      }
      {
        at = ren.kinds.mac;
        into = { ... }: ms: { darwin.imports = ms; };
      }
    ];

    homeManager = [
      # one class, four homes
      {
        at = and [
          ren.kinds.user
          (within ren.kinds.host)
        ];
        into = { user, ... }: ms: { nixos.home-manager.users.${user.name}.imports = ms; };
      }
      {
        at = and [
          ren.kinds.user
          (within ren.kinds.mac)
        ];
        into = { user, ... }: ms: { darwin.home-manager.users.${user.name}.imports = ms; };
      }
      {
        at = and [
          ren.kinds.user
          (within ren.kinds.phone)
        ];
        into = { ... }: ms: { droid.home-manager.config.imports = ms; };
      }
      {
        at = and [
          ren.kinds.user
          (within ren.kinds.home)
        ]; # standalone
        into = { home, ... }: ms: {
          homeConfigurations.${home.name} = home.channel.home-manager.lib.homeManagerConfiguration {
            pkgs = pkgsOf home;
            modules = ms;
          };
        };
      }
    ];

    homeDarwin = {
      # a sub-class, forwarded in place
      at = and [
        ren.kinds.user
        (within ren.kinds.mac)
      ];
      into = { ... }: ms: { homeManager.imports = ms; };
    };

    droid = {
      at = ren.kinds.phone;
      into = { phone, ... }: ms: {
        nixOnDroidConfigurations.${phone.name} = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgsOf phone;
          modules = ms;
        };
      };
    };

    terraform = {
      at = and [
        ren.kinds.environment
        (when (s: s.environment.edge))
      ];
      into = { ... }: ms: {
        terraformConfigurations.dns = inputs.terranix.lib.terranixConfiguration {
          system = "x86_64-linux";
          modules = ms;
        };
      };
    };

  };

  # ══ KINDS — below = child kinds; spawns.<child> = s: instances (gen-scope mkKind, parent side) ══
  # A kind no `below` lists has no scopes: data (channel, group, db, region) or abstract (machine).
  ren.kinds = {
    fleet = {
      below = [
        ren.kinds.system
        ren.kinds.environment
        ren.kinds.home
        ren.kinds.replica
      ];
    }; # spawns default: every instance
    system = { };
    channel = {
      nixpkgs = t.raw;
      home-manager = t.raw;
      darwin = opt t.raw null;
    };
    group = {
      members = opt (t.listOf ren.kinds.group) [ ];
    };

    environment = {
      below = [
        ren.kinds.host
        ren.kinds.mac
        ren.kinds.phone
      ];
      spawns = {
        host = inEnv ren.host;
        mac = inEnv ren.mac;
        phone = inEnv ren.phone;
      };
      grants = t.listOf ren.kinds.group;
      edge = opt t.bool false;
      inherits = maybe ren.kinds.environment;
      settings = opt settingsT { };
    };

    machine = {
      # abstract: no `below` lists it
      environment = ren.kinds.environment;
      channel = ren.kinds.channel;
      system = ren.kinds.system;
      addr = t.str;
      settings = opt settingsT { };
    };
    host = {
      is = ren.kinds.machine;
      below = [
        ren.kinds.user
        ren.kinds.guest
      ];
      spawns = {
        user = usersOn;
        guest = s: lib.filterAttrs (_: g: same g.on s.host) ren.guest;
      };
    };
    mac = {
      is = ren.kinds.machine;
      below = [ ren.kinds.user ];
      spawns.user = usersOn;
    };
    guest = {
      is = ren.kinds.host; # declares its own `below`: no guest in a guest
      below = [ ren.kinds.user ];
      spawns.user = usersOn;
      on = ren.kinds.host;
    };

    phone = {
      below = [ ren.kinds.user ];
      spawns.user = _: lib.filterAttrs (_: u: u.phone) ren.user;
      environment = ren.kinds.environment;
      channel = ren.kinds.channel;
      system = ren.kinds.system;
    };
    home = {
      below = [ ren.kinds.user ];
      spawns.user = s: { ${s.home.user.name} = s.home.user; }; # standalone
      user = ren.kinds.user;
      channel = ren.kinds.channel;
      system = ren.kinds.system;
    };

    user = {
      # each parent says how it spawns users
      groups = t.listOf ren.kinds.group;
      phone = opt t.bool false;
    };

    db.zone = t.str;
    region.zone = t.str;
    replica = { db, region }: when (s: s.db.zone == s.region.zone) { };
  };

  # ══ INSTANCES ═════════════════════════════════════════════════════════
  ren.fleet.main = { };
  ren.system.x86_64-linux = { };
  ren.system.aarch64-linux = { };
  ren.system.aarch64-darwin = { };

  ren.channel.stable = {
    nixpkgs = inputs.nixpkgs;
    home-manager = inputs.home-manager;
    darwin = inputs.nix-darwin;
  };
  ren.channel.edge = {
    nixpkgs = inputs.nixpkgs-unstable;
    home-manager = inputs.home-manager-unstable;
  };

  ren.group.ops = { };
  ren.group.admin = {
    members = [ ren.group.ops ];
  };
  ren.group.deploy = { };

  ren.environment.prod = {
    grants = [ ren.group.admin ];
    edge = true;
    settings.kernel.channel = "lts";
  };
  ren.environment.staging = {
    grants = [
      ren.group.admin
      ren.group.deploy
    ];
    inherits = ren.environment.prod;
  };

  ren.host.lb = {
    environment = ren.environment.prod;
    channel = ren.channel.stable;
    system = ren.system.x86_64-linux;
    addr = "10.0.1.1";
  };
  ren.host.web-1 = {
    environment = ren.environment.prod;
    channel = ren.channel.stable;
    system = ren.system.x86_64-linux;
    addr = "10.0.1.10";
    settings.kernel.channel = "latest";
  };
  ren.host.web-2 = {
    environment = ren.environment.prod;
    channel = ren.channel.stable;
    system = ren.system.x86_64-linux;
    addr = "10.0.1.11";
  };
  ren.host.stage = {
    environment = ren.environment.staging;
    channel = ren.channel.edge;
    system = ren.system.x86_64-linux;
    addr = "10.0.2.10";
  };
  ren.guest.ci = {
    environment = ren.environment.staging;
    channel = ren.channel.stable;
    system = ren.system.x86_64-linux;
    addr = "10.0.2.20";
    on = ren.host.stage;
  };
  ren.mac.studio = {
    environment = ren.environment.staging;
    channel = ren.channel.stable;
    system = ren.system.aarch64-darwin;
    addr = "10.0.2.30";
  };
  ren.phone.pixel = {
    environment = ren.environment.staging;
    channel = ren.channel.stable;
    system = ren.system.aarch64-linux;
  };
  ren.home.alice-laptop = {
    user = ren.user.alice;
    channel = ren.channel.edge;
    system = ren.system.x86_64-linux;
  };

  ren.user.alice = {
    groups = [ ren.group.ops ];
    phone = true;
  }; # admin through the closure
  ren.user.bob = {
    groups = [ ren.group.deploy ];
  };

  ren.db.primary.zone = "eu";
  ren.region.eu.zone = "eu";
  ren.replica.r1 = {
    db = ren.db.primary;
    region = ren.region.eu;
  };

  # ══ CHANNELS — data (gen-aspects `channel`); at = emitters (default any), to = e: receivers ══
  ren.channels = {
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
    persist = {
      fold = set;
      at = anyOf [
        ren.kinds.host
        (and [
          ren.kinds.user
          (within ren.kinds.host)
        ])
      ];
      to = e: e.host;
    }; # STIMPY-C1
    flake-inputs = {
      fold = attrs;
      to = _: ren.fleet.main; # no `at`: any scope emits
      into = { ... }: inputs': { flake-file.inputs = inputs'; };
    };
    meta = {
      fold = set;
      to = e: e;
    };

    # channels with `into`: data collectors (not module systems, so not classes)
    packages = {
      fold = attrs;
      at = ren.kinds.system;
      to = e: e;
      into = { system, ... }: pkgs': { packages.${system.name} = pkgs'; };
    };
    colmena = {
      fold = attrs;
      at = metal;
      to = _: ren.fleet.main; # fed by the nixos collector
      into = { ... }: nodes: {
        colmenaHive = inputs.colmena.lib.makeHive (
          { meta.nixpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; } // nodes
        );
      };
    };
    age-manifest = {
      fold = attrs;
      at = metal;
      to = _: ren.fleet.main; # fed by the nixos collector
      into = { ... }: m: { ageManifest = m; };
    };
  };

  # ══ ASPECTS — `at` activates; no `at` = only where included ═══════════
  ren.aspects = {

    base = {
      at = ren.kinds.machine;
      os = { machine, overlays, ... }: {
        networking.hostName = machine.name;
        nixpkgs.overlays = overlays;
      };
      records = { machine, ... }: { ${machine.name} = machine.addr; };
    };
    deploy-record = {
      at = metal;
      deployment = { host, meta, ... }: {
        address = host.addr;
        user = "deploy";
        tags = meta;
      };
    };

    hm-module = {
      # bundle: each key lands where its class lives
      at = ren.kinds.machine;
      nixos = { host, ... }: { imports = [ host.channel.home-manager.nixosModules.home-manager ]; };
      darwin = { mac, ... }: { imports = [ mac.channel.home-manager.darwinModules.home-manager ]; };
    };
    secrets = {
      at = ren.kinds.host;
      nixos.imports = [ inputs.agenix.nixosModules.default ];
      flake-inputs = { ... }: { agenix.url = "github:ryantm/agenix"; };
    };

    vm = {
      at = ren.kinds.guest;
      nixos.imports = [ inputs.microvm.nixosModules.microvm ];
      flake-inputs = { ... }: { microvm.url = "github:microvm-nix/microvm.nix"; };
    };
    vm-host = {
      at = and [
        metal
        (has ren.kinds.guest)
      ];
      nixos.imports = [ inputs.microvm.nixosModules.host ];
    };

    unstable-overlay = {
      # a function value: wrap it in `{ ... }:`
      at = ren.fleet.main;
      overlays = { ... }: final: prev: {
        inherit (inputs.nixpkgs-unstable.legacyPackages.${prev.system}) helix;
      };
    };

    # ── cross-scope by predicate ──
    ssh-agent = {
      at = and [
        ren.kinds.user
        (within ren.kinds.machine)
      ];
      homeManager.services.ssh-agent.enable = true;
    };
    docker = {
      at = and [
        ren.kinds.host
        (has ren.user.bob)
      ]; # the hosts bob lives on
      nixos.virtualisation.docker.enable = true;
      persist = { ... }: "/var/lib/docker";
    };
    htop = {
      at = and [
        ren.user.alice
        (within ren.host.web-1)
      ];
      homeManager.programs.htop.enable = true;
    };

    desktop = {
      at = ren.host.stage;
      nixos.services.xserver.enable = true;
    };
    dock = {
      at = ren.kinds.mac;
      darwin.system.defaults.dock.autohide = true;
    };
    tiling = {
      at = ren.kinds.user; # lands only on mac users
      homeDarwin.programs.aerospace.enable = true;
    };

    motd = {
      at = ren.kinds.machine;
      os.environment.etc.motd.text = "managed by ren"; # C10
    };
    motd-short = {
      os.environment.etc.motd.text = "ren"; # C10
    }; # included only
    quiet = {
      at = ren.host.web-2;
      excludes = [ ren.aspects.motd ];
      includes = [ ren.aspects.motd-short ];
    };

    http-port = {
      at = and [
        ren.kinds.host
        ren.aspects.nginx
      ]; # an aspect ref = "active here"
      nixos.networking.firewall.allowedTCPPorts = [ 80 ];
    };

    kernel = {
      at = ren.kinds.host;
      nixos =
        {
          host,
          environment,
          pkgs,
          ...
        }:
        let
          k = first [
            host.settings.kernel.channel
            environment.settings.kernel.channel
            (environment.inherits.settings.kernel.channel or null)
            "latest"
          ];
        in
        {
          boot.kernelPackages = if k == "lts" then pkgs.linuxPackages else pkgs.linuxPackages_latest;
        };
    };

    impermanence = {
      at = metal;
      nixos = { persist, ... }: {
        imports = [ inputs.impermanence.nixosModules.impermanence ];
        environment.persistence."/persist".directories = persist;
      };
    };

    dev = {
      at = anyOf [
        ren.kinds.machine
        ren.kinds.user
      ];
      # C8
      os =
        { pkgs, ... }:
        {
          environment.systemPackages = [ pkgs.git ];
        };
      homeManager = {
        programs.git.enable = true;
      };
    };

    hm-state = {
      at = ren.kinds.user;
      homeManager.home.stateVersion = "25.05";
    }; # C9

    hm-standalone = {
      at = and [
        ren.kinds.user
        (within ren.kinds.home)
      ];
      homeManager =
        { user, ... }:
        {
          home.username = user.name;
          home.homeDirectory = "/home/${user.name}";
        };
    }; # C12

    sync = {
      at = ren.kinds.user;
      devices = { parent, ... }: parent.name;
      persist = { user, ... }: "/home/${user.name}/.local/state/syncthing";
      homeManager =
        {
          devices,
          parent,
          lib,
          ...
        }:
        {
          services.syncthing.enable = true;
          services.syncthing.settings.devices = lib.genAttrs devices (n: {
            id = builtins.hashString "sha256" n;
          }); # C11
          services.syncthing.tray.enable = is ren.aspects.desktop parent; # same `is` as everywhere
        };
    };

    tools = {
      at = ren.kinds.system;
      packages = { system, ... }: { inherit (inputs.nixpkgs.legacyPackages.${system.name}) hello; };
    };

    dns = {
      at = ren.environment.prod;
      terraform = { records, lib, ... }: {
        resource.cloudflare_record = lib.mapAttrs (_: addr: {
          value = addr;
          type = "A";
        }) records;
      };
    };

    replica-scrape = {
      at = ren.kinds.replica;
      scrape =
        {
          db,
          region,
          replica,
          ...
        }:
        {
          job = replica.name;
          target = "${db.zone}.${region.zone}:9090";
        };
    };

    # ── included only ──
    nginx = {
      nixos.services.nginx.enable = true;
      meta = { ... }: "web";
      backends = { host, ... }: host.addr;
      persist = { ... }: "/var/lib/nginx";
    };
    haproxy.nixos = { backends, lib, ... }: {
      services.haproxy.enable = true;
      services.haproxy.config = lib.concatMapStrings (a: "  server ${a} ${a}:80 check\n") backends;
    };
    monitoring.nixos = { scrape, ... }: {
      services.prometheus.scrapeConfigs = map (j: {
        job_name = j.job;
        static_configs = [ { targets = [ j.target ]; } ];
      }) scrape;
    };

    # ── activators ──
    lb = {
      at = ren.host.lb;
      includes = [
        ren.aspects.haproxy
        ren.aspects.monitoring
      ];
    };
    web = {
      at = anyOf [
        ren.host.web-1
        ren.host.web-2
        ren.host.stage
      ];
      includes = [ ren.aspects.nginx ];
    };
  };
}
