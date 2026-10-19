# Ren fleet demo — v28 (2026-10-18)

v28 = vic adopted genie's v27.A fork (gist `c87dd7a4`) whole. v27.A = genie's fork of vic's v27 (gist `fd908191`). v26 = genie's v25.A fork (gist `81b58e75`), adopted by vic, plus flake-file inputs. Outputs and tool options are all top-level options. Design only; nothing implements it. Feedback goes after `> VIC:` lines.

## What changed from v27 (genie, v27.A)

| change | why |
|---|---|
| **`attrs` recurses into attrsets.** Equal leaves dedup, different leaves are an error. | Under a shallow union the v27 fleet fails: every metal host returns `deploy.nodes.<h>`, so the top-level `deploy` values differ and conflict. The same goes for `colmena.<h>` forwards, and for `flake-inputs` when one feature adds `inputs.nixpkgs.follows` to an input another only gives a `url`. |
| **Each fold is also a function on lists,** usable in `into`: `packages.${system.name} = attrs ms`. | v27's `packages` used `lib.mergeAttrsList`, which is last-wins: the one place left where a conflict was silent. |
| **New predicate `anywhere`,** meaning the root scope or anything within it. | `from = within ren.kinds.fleet` leaves out the root itself, because `within` means a *strict* ancestor. A fleet-level feature (`unstable-overlay`) emitting `flake-inputs` or `meta` would be silently lost. |
| **Stratum 3 is checked per collector branch, not per target.** | `homeManager` forwards into `nixos` (branch 1), so under a per-target check *no* `homeManager` branch may read `outputs.nixosConfigurations`. That kills Den's home-with-`osConfig` row below. The standalone-home branch forwards nowhere, so per branch it is legal. |
| **Guarded forward: guard on scope data, not on `options`.** | v27's `map (m: { options, ... }: lib.optionalAttrs (options ? x) m) ms` breaks in two ways. `m` is usually a function, so `optionalAttrs` can't take it. And a module's `imports` can't depend on `options`/`config`, so the module system recurses forever. Guard in stratum 0/1 instead (`at`, `has`), or put `lib.mkIf` around a config *value*. |
| **flake-file *does* fetch only active features' inputs.** | v27 listed it as impossible for flakes. But its own flake-file row writes only active features' inputs, so the regenerated `flake.nix` fetches exactly those. The cost is a regeneration step whenever activation changes, not impossibility. |

## What changed from v25 (genie, v25.A)

| change | why |
|---|---|
| **Signals use `from`/`to`.** The `environment.from` field is now `inherits`. | `at` means "where it activates" everywhere else. A signal has an emitter and a receiver, so name both. |
| **`fold` takes one of four named laws: `list`, `set`, `attrs`, `one`.** `list` is ordered by emitter scope path. | v25 claimed every fold is commutative and idempotent, but `list` is neither, and haproxy text depends on its order. `one` fixes the `deployment` bug (v25 handed `into` a list). |
| **Stratum-0 predicates `within K` and `contains K`.** | `when (s: s ? host)` and `when (s: granted s bob)` restated the scope tree by hand. `docker` silently diverges if bob's grant changes. These are gen-select's `within` and `has` (match.nix:122, :119), so they cost nothing. |
| **Every scope binds `parent`,** the instance of its direct parent. | The syncthing `devices` emission needed `host ? null, phone ? null` branching. Now it's `parent.name`, for any parent kind. |
| **An abstract kind `machine`.** `host` (nixos) and `mac` (darwin) are both `is = machine`, and `guest` is `is = host`. | Gives darwin and the Den `os` class a home without a platform flag, and features can target either level. |
| **Instance names are unique across a kind and its subtypes.** | Through `is`, `ren.host.x` and `ren.guest.x` would collide on `host.name`, in nixosConfigurations and in `records` keys. |
| **The guest collector sets `pkgs` from `guest.channel`.** | In v25 the guest's channel was silently ignored: it built with the parent's pkgs. |
| **home-manager and agenix modules are imported,** from the scope's channel. | Without them the HM and stratum-3 rows failed on unknown options rather than testing anything. |
| **Output merge is the `attrs` law.** | Many scopes write `nixosConfigurations.*`. Equal leaves dedup and different leaves are an error, the same law as pools: one rule, not two. |
| **v26 (vic): `into` returns top-level options.** `nixosConfigurations` and `flake-file.inputs` are both top-level options; a `flake-inputs` signal (fold `attrs`) feeds a `flake-file` collector. | Features declare their own flake inputs ([flake-file](~/hk/flake-file), Den #348 / #336). Inputs leave scopes only through a signal, the same rule as everything else. |
| **Content-function rule:** content is a value, or a function with a formals set `{ … }:`. A value that is itself a function is wrapped. | An overlay `final: prev:` would otherwise be read as content asking for bindings. Den hit this (issue-408, bare-function aspects). |

## Vocabulary

- **targets**: a collector `{ at; into; }` or a list of collectors. List branches must be disjoint (overlap = eval error).
  - `into = { <bindings>, <pools>, outputs, ... }: ms: { … }`. Returned keys:
    - a key that names a target **forwards**. It lands in the same scope if that scope collects the target, else in the nearest ancestor that does. Forwards are acyclic.
    - any other key is a **top-level option** of the flake module: `nixosConfigurations`, `packages`, `flake-file.inputs`, … all sit side by side. All scopes merge by the `attrs` law.
  - `ms` is whatever the features wrote under this target's key: modules for module systems, plain attrsets for `packages`. `into` decides what a contribution is.
  - `outputs` is the realized outputs of other targets (stratum 3). The check runs on the **collector** graph (one node per branch): a branch may read target X's outputs only if it does not forward, directly or transitively, into X.
- **kinds**: typed, strict data. Reserved keys are `at` and `is`.
  - `at` says where instances exist. `spawn K f` creates children under each scope matching `K`. `any [ spawn … ]` gives a kind several parents. An instance appears at most once on a path.
  - A kind with no `at` and no instances is **abstract**: it exists only to be `is`-ed.
  - `is = K`: a subtype. Its scopes match `ren.kinds.K`, bind `K` to themselves, and have K's fields. Names are unique across a kind and all its subtypes.
- **instances**: `ren.<kind>.<name>`. One instance can have many scopes (alice under each host).
- **scope bindings**: every ancestor instance by kind name, the scope's own instance, and `parent`.
- **signals**: `{ from; to; fold; }`. Reserved keys are `from`, `to` and `fold`.
  - `from` says which scopes emit. `to = e: <predicate>` says which scopes receive from emitter scope `e`. `e.<kind>` is an instance bound on e's path.
  - `fold` is one of:
    - `list`: ordered by emitter scope path. Not commutative.
    - `set`: dedup and sort. Commutative and idempotent.
    - `attrs`: recursive union; equal leaves dedup, different leaves are an error. Commutative and idempotent.
  - Each fold is also a function `[ v ] -> v`, so `into` can apply the same law to `ms` (`attrs ms`).
    - `one`: exactly one emitter; zero or two is an error.
- **features**: reserved keys are `at`, `take` and `omit`.
  - `at` activates. A feature without `at` fires only where taken.
  - `take` includes and `omit` excludes, in this feature's scopes and their subtrees. Substitute = `omit` + `take`.
  - A key naming a target is config; a key naming a signal is an emission; any other key is an eval error.
  - A key that lands in **none** of the feature's active scopes is an eval error. Bundles are fine: `dev.nixos` landing nowhere on a mac is fine if it lands on some host.
  - Content args are the scope bindings, the pools that reach the scope, `has`, `features`, and normal module args.
- **predicates**: `all any unless when within contains anywhere has same`.
  - A kind ref matches scopes of that kind (or a subtype). An instance ref (or `e`) matches that instance's scopes.
  - `within X`: some strict ancestor matches X. `contains X`: some child matches X. `anywhere`: every scope, root included. All read only the scope tree (stratum 0).
  - `has F` / `has F x`: feature F is active here, or in x's nearest scope (stratum 1).
  - `when f`: `f` sees the scope bindings only.

## Fleet

```nix
let
  inherit (ren.lib) all any unless when within contains anywhere has spawn same;
  inherit (ren.lib.fold) list set attrs one;
  t = lib.types;

  opt   = type: default: lib.mkOption { inherit type default; };
  maybe = type: opt (t.nullOr type) null;
  first = lib.findFirst (v: v != null) null;                       # nearest non-null wins

  pkgsOf = m: m.channel.nixpkgs.legacyPackages.${m.system.name};   # m: anything with channel + system
  inEnv  = xs: s: lib.filterAttrs (_: x: same x.environment s.environment) xs;

  metal = all [ ren.kinds.host (unless ren.kinds.guest) ];          # physical nixos hosts

  settingsT = t.submodule { options.kernel.channel = maybe (t.enum [ "lts" "latest" ]); };

  closure = gs: map (x: x.g) (lib.genericClosure {                  # nested groups
    startSet = map (g: { key = g.name; inherit g; }) gs;
    operator = x: map (p: { key = p.name; g = p; })
      (lib.filter (p: lib.any (same x.g) p.members) (lib.attrValues ren.group));
  });
  granted = s: u: lib.any (g: lib.any (same g) s.environment.grants) (closure u.groups);
in
ren.lib.mkFlake inputs {

  # ══ TARGETS ═══════════════════════════════════════════════════════════
  ren.targets = {

    nixos = [
      { at = metal;
        into = { host, deployment, ... }: ms: {
          nixosConfigurations.${host.name} =
            host.channel.nixpkgs.lib.nixosSystem { system = host.system.name; modules = ms; };
          colmena.${host.name} = { imports = ms; deployment = { targetHost = deployment.address; inherit (deployment) tags; }; };
          deploy.nodes.${host.name} = { hostname = deployment.address; sshUser = deployment.user; };
        }; }
      { at = ren.kinds.guest;                                       # forwards to the physical host
        into = { guest, ... }: ms: {
          nixos.microvm.vms.${guest.name} = { pkgs = pkgsOf guest; config.imports = ms; };
        }; }
    ];

    darwin = {
      at   = ren.kinds.mac;
      into = { mac, ... }: ms: {
        darwinConfigurations.${mac.name} =
          mac.channel.darwin.lib.darwinSystem { system = mac.system.name; modules = ms; };
      };
    };

    os = [                                                          # Den `os`: one key, either OS
      { at = ren.kinds.host; into = { ... }: ms: { nixos.imports  = ms; }; }
      { at = ren.kinds.mac;  into = { ... }: ms: { darwin.imports = ms; }; }
    ];

    homeManager = [                                                 # one target, four homes
      { at = all [ ren.kinds.user (within ren.kinds.host) ];
        into = { user, ... }: ms: { nixos.home-manager.users.${user.name}.imports = ms; }; }
      { at = all [ ren.kinds.user (within ren.kinds.mac) ];
        into = { user, ... }: ms: { darwin.home-manager.users.${user.name}.imports = ms; }; }
      { at = all [ ren.kinds.user (within ren.kinds.phone) ];
        into = { ... }: ms: { droid.home-manager.config.imports = ms; }; }
      { at = all [ ren.kinds.user (within ren.kinds.home) ];       # standalone
        into = { home, ... }: ms: {
          homeConfigurations.${home.name} =
            home.channel.home-manager.lib.homeManagerConfiguration { pkgs = pkgsOf home; modules = ms; };
        }; }
    ];

    homeDarwin = {                                                  # Den hmPlatforms: a sub-target, forwarded in place
      at   = all [ ren.kinds.user (within ren.kinds.mac) ];
      into = { ... }: ms: { homeManager.imports = ms; };            # same scope collects homeManager
    };

    droid = {
      at   = ren.kinds.phone;
      into = { phone, ... }: ms: {
        nixOnDroidConfigurations.${phone.name} =
          inputs.nix-on-droid.lib.nixOnDroidConfiguration { pkgs = pkgsOf phone; modules = ms; };
      };
    };

    packages = {                                                    # not a module system
      at   = ren.kinds.system;
      into = { system, ... }: ms: { packages.${system.name} = attrs ms; };
    };

    terraform = {
      at   = all [ ren.kinds.environment (when (s: s.environment.edge)) ];
      into = { ... }: ms: {
        terraformConfigurations.dns =
          inputs.terranix.lib.terranixConfiguration { system = "x86_64-linux"; modules = ms; };
      };
    };

    colmena = {
      at   = ren.kinds.fleet;
      into = { ... }: ms: {
        colmenaHive = inputs.colmena.lib.makeHive
          (lib.foldl' lib.recursiveUpdate { meta.nixpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; } ms);
      };
    };

    flake-file = {                                                  # ~/hk/flake-file: inputs gathered from features
      at   = ren.kinds.fleet;
      into = { flake-inputs, ... }: _: { flake-file.inputs = flake-inputs; };   # a top-level option, like nixosConfigurations
    };

    manifest = {                                                    # stratum 3
      at   = ren.kinds.fleet;
      into = { outputs, ... }: _: {
        ageManifest = lib.mapAttrs (_: c: lib.attrNames c.config.age.secrets) outputs.nixosConfigurations;
      };
    };
  };

  # ══ KINDS ═════════════════════════════════════════════════════════════
  ren.kinds = {
    fleet   = { };
    system  = { at = spawn ren.kinds.fleet (_: ren.system); };
    channel = { nixpkgs = t.raw; home-manager = t.raw; darwin = opt t.raw null; };
    group   = { members = opt (t.listOf ren.kinds.group) [ ]; };

    environment = {
      at       = spawn ren.kinds.fleet (_: ren.environment);
      grants   = t.listOf ren.kinds.group;
      edge     = opt t.bool false;
      inherits = maybe ren.kinds.environment;
      settings = opt settingsT { };
    };

    machine = {                                                     # abstract: no `at`, no instances
      environment = ren.kinds.environment;
      channel     = ren.kinds.channel;
      system      = ren.kinds.system;
      addr        = t.str;
      settings    = opt settingsT { };
    };
    host  = { is = ren.kinds.machine; at = spawn ren.kinds.environment (inEnv ren.host); };
    mac   = { is = ren.kinds.machine; at = spawn ren.kinds.environment (inEnv ren.mac); };
    guest = {
      is = ren.kinds.host;
      at = spawn metal (s: lib.filterAttrs (_: g: same g.on s.host) ren.guest);
      on = ren.kinds.host;
    };

    phone = { at = spawn ren.kinds.environment (inEnv ren.phone);
              environment = ren.kinds.environment; channel = ren.kinds.channel; system = ren.kinds.system; };
    home  = { at = spawn ren.kinds.fleet (_: ren.home);             # standalone home-manager
              user = ren.kinds.user; channel = ren.kinds.channel; system = ren.kinds.system; };

    user = {
      at = any [
        (spawn ren.kinds.machine (s: lib.filterAttrs (_: granted s) ren.user))
        (spawn ren.kinds.phone   (_: lib.filterAttrs (_: u: u.phone) ren.user))
        (spawn ren.kinds.home    (s: { ${s.home.user.name} = s.home.user; }))
      ];
      groups = t.listOf ren.kinds.group;
      phone  = opt t.bool false;
    };

    db.zone     = t.str;
    region.zone = t.str;
    replica     = { db, region }: when (s: s.db.zone == s.region.zone) { };
  };

  # ══ INSTANCES ═════════════════════════════════════════════════════════
  ren.fleet.main = { };
  ren.system.x86_64-linux   = { };
  ren.system.aarch64-linux  = { };
  ren.system.aarch64-darwin = { };

  ren.channel.stable = { nixpkgs = inputs.nixpkgs;          home-manager = inputs.home-manager;          darwin = inputs.nix-darwin; };
  ren.channel.edge   = { nixpkgs = inputs.nixpkgs-unstable; home-manager = inputs.home-manager-unstable; };

  ren.group.ops    = { };
  ren.group.admin  = { members = [ ren.group.ops ]; };
  ren.group.deploy = { };

  ren.environment.prod    = { grants = [ ren.group.admin ]; edge = true; settings.kernel.channel = "lts"; };
  ren.environment.staging = { grants = [ ren.group.admin ren.group.deploy ]; inherits = ren.environment.prod; };

  ren.host.lb     = { environment = ren.environment.prod;    channel = ren.channel.stable; system = ren.system.x86_64-linux; addr = "10.0.1.1";  };
  ren.host.web-1  = { environment = ren.environment.prod;    channel = ren.channel.stable; system = ren.system.x86_64-linux; addr = "10.0.1.10"; settings.kernel.channel = "latest"; };
  ren.host.web-2  = { environment = ren.environment.prod;    channel = ren.channel.stable; system = ren.system.x86_64-linux; addr = "10.0.1.11"; };
  ren.host.stage  = { environment = ren.environment.staging; channel = ren.channel.edge;   system = ren.system.x86_64-linux; addr = "10.0.2.10"; };
  ren.guest.ci    = { environment = ren.environment.staging; channel = ren.channel.stable; system = ren.system.x86_64-linux; addr = "10.0.2.20"; on = ren.host.stage; };
  ren.mac.studio  = { environment = ren.environment.staging; channel = ren.channel.stable; system = ren.system.aarch64-darwin; addr = "10.0.2.30"; };
  ren.phone.pixel = { environment = ren.environment.staging; channel = ren.channel.stable; system = ren.system.aarch64-linux; };
  ren.home.alice-laptop = { user = ren.user.alice; channel = ren.channel.edge; system = ren.system.x86_64-linux; };

  ren.user.alice = { groups = [ ren.group.ops ]; phone = true; };    # admin through the closure
  ren.user.bob   = { groups = [ ren.group.deploy ]; };

  ren.db.primary.zone = "eu";
  ren.region.eu.zone  = "eu";
  ren.replica.r1      = { db = ren.db.primary; region = ren.region.eu; };

  # ══ SIGNALS — from = who emits; to = e: who receives ═════════════════
  ren.signals = {
    backends = { fold = list;  from = ren.kinds.host;
                 to = e: all [ ren.kinds.host (when (r: same r.host.environment e.host.environment))
                               (unless e) (unless (has ren.features.nginx)) ]; };
    devices    = { fold = set;   from = ren.kinds.user;    to = e: all [ ren.kinds.user (when (r: same r.user e.user)) (unless e) ]; };
    records    = { fold = attrs; from = ren.kinds.machine; to = _: ren.environment.prod; };
    deployment = { fold = one;   from = metal;             to = e: e; };
    scrape     = { fold = list;  from = ren.kinds.replica; to = _: ren.host.lb; };
    overlays   = { fold = list;  from = ren.kinds.fleet;   to = _: ren.kinds.machine; };
    persist    = { fold = set;   from = any [ ren.kinds.host ren.kinds.user ]; to = e: e.host; };   # host, or the user's host
    flake-inputs = { fold = attrs; from = anywhere; to = _: ren.fleet.main; };   # any scope, root included → root
    meta         = { fold = set;   from = anywhere; to = e: e; };                             # feature metadata is just an emission
  };

  # ══ FEATURES ══════════════════════════════════════════════════════════
  ren.features = {

    base = {
      at      = ren.kinds.machine;
      os      = { machine, overlays, ... }: { networking.hostName = machine.name; nixpkgs.overlays = overlays; };
      records = { machine, ... }: { ${machine.name} = machine.addr; };
    };
    deploy-record = {
      at         = metal;
      deployment = { host, meta, ... }: { address = host.addr; user = "deploy"; tags = meta; };
    };

    hm-module = {                                                   # bundle: each key lands where its target lives
      at     = ren.kinds.machine;
      nixos  = { host, ... }: { imports = [ host.channel.home-manager.nixosModules.home-manager ]; };
      darwin = { mac, ... }:  { imports = [ mac.channel.home-manager.darwinModules.home-manager ]; };
    };
    secrets = { at = ren.kinds.host;
                nixos.imports = [ inputs.agenix.nixosModules.default ];
                flake-inputs  = { ... }: { agenix.url = "github:ryantm/agenix"; }; };

    vm      = { at = ren.kinds.guest;
                nixos.imports = [ inputs.microvm.nixosModules.microvm ];
                flake-inputs  = { ... }: { microvm.url = "github:microvm-nix/microvm.nix"; }; };
    vm-host = { at = all [ metal (contains ren.kinds.guest) ]; nixos.imports = [ inputs.microvm.nixosModules.host ]; };

    unstable-overlay = {                                           # a function value: wrap it in `{ ... }:`
      at       = ren.fleet.main;
      overlays = { ... }: final: prev: { inherit (inputs.nixpkgs-unstable.legacyPackages.${prev.system}) helix; };
    };

    # ── cross-scope by predicate: Den provides.to-users / to-hosts ──
    ssh-agent = { at = all [ ren.kinds.user (within ren.kinds.machine) ]; homeManager.services.ssh-agent.enable = true; };
    docker    = { at = all [ ren.kinds.host (contains ren.user.bob) ];   # the hosts bob lives on, said once
                  nixos.virtualisation.docker.enable = true;
                  persist = { ... }: "/var/lib/docker"; };
    htop      = { at = all [ ren.user.alice (within ren.host.web-1) ]; homeManager.programs.htop.enable = true; };   # Den "alice@web-1"

    desktop = { at = ren.host.stage; nixos.services.xserver.enable = true; };
    dock    = { at = ren.kinds.mac;  darwin.system.defaults.dock.autohide = true; };
    tiling  = { at = ren.kinds.user;                              # lands only on mac users
                homeDarwin.programs.aerospace.enable = true; };

    motd       = { at = ren.kinds.machine; os.users.motd = "managed by ren"; };
    motd-short = { os.users.motd = "ren"; };                        # taken only
    quiet      = { at = ren.host.web-2; omit = [ ren.features.motd ]; take = [ ren.features.motd-short ]; };   # substitute

    http-port = { at = all [ ren.kinds.host (has ren.features.nginx) ];
                  nixos.networking.firewall.allowedTCPPorts = [ 80 ]; };

    kernel = {
      at    = ren.kinds.host;
      nixos = { host, environment, pkgs, ... }:
        let k = first [ host.settings.kernel.channel environment.settings.kernel.channel
                        (environment.inherits.settings.kernel.channel or null) "latest" ];
        in { boot.kernelPackages = if k == "lts" then pkgs.linuxPackages else pkgs.linuxPackages_latest; };
    };

    impermanence = {
      at    = metal;
      nixos = { persist, ... }: {
        imports = [ inputs.impermanence.nixosModules.impermanence ];
        environment.persistence."/persist".directories = persist;
      };
    };

    dev = {                                                         # bundle across OS and home
      at          = any [ ren.kinds.machine ren.kinds.user ];
      os          = { programs.git.enable = true; };
      homeManager = { programs.git.enable = true; };
    };

    sync = {
      at          = ren.kinds.user;
      devices     = { parent, ... }: parent.name;                   # any parent kind
      persist     = { user, ... }: "/home/${user.name}/.local/state/syncthing";
      homeManager = { devices, parent, has, lib, ... }: {
        services.syncthing.enable           = true;
        services.syncthing.settings.devices = lib.genAttrs devices (_: { });
        services.syncthing.tray.enable      = has ren.features.desktop parent;
      };
    };

    tools = { at = ren.kinds.system;                                # per-system flake outputs
              packages = { system, ... }: { inherit (inputs.nixpkgs.legacyPackages.${system.name}) hello; }; };

    dns = { at = ren.environment.prod;
            terraform = { records, lib, ... }: {
              resource.cloudflare_record = lib.mapAttrs (_: addr: { value = addr; type = "A"; }) records; }; };

    replica-scrape = { at = ren.kinds.replica;
                       scrape = { db, region, replica, ... }: { job = replica.name; target = "${db.zone}.${region.zone}:9090"; }; };

    # ── taken only ──
    nginx = { nixos.services.nginx.enable = true;
              meta     = { ... }: "web";
              backends = { host, ... }: host.addr;
              persist  = { ... }: "/var/lib/nginx"; };
    haproxy.nixos = { backends, lib, ... }: { services.haproxy.enable = true;
      services.haproxy.config = lib.concatMapStrings (a: "  server ${a} ${a}:80 check\n") backends; };
    monitoring.nixos = { scrape, ... }: {
      services.prometheus.scrapeConfigs = map (j: { job_name = j.job; static_configs = [ { targets = [ j.target ]; } ]; }) scrape; };

    # ── activators ──
    lb  = { at = ren.host.lb; take = [ ren.features.haproxy ren.features.monitoring ]; };
    web = { at = any [ ren.host.web-1 ren.host.web-2 ren.host.stage ]; take = [ ren.features.nginx ]; };
  };
}
```

## Evaluation order (strata)

| stratum | computes | reads | a cycle inside it is |
|---|---|---|---|
| 0 scopes | `spawn` tree, `is`, `parent`, `within`, `contains` | instances, `same`, `when` on bindings | impossible: an instance appears once per path |
| 1 activation | `at`, `take`, `omit`, `has` in predicates | stratum 0 | an eval error "not stratified" if it passes through `unless`/`omit` |
| 2 content | feature values, pools (`fold`), `has F x`, `features` | strata 0–1, pools (lazy) | Nix infinite recursion: never a wrong value |
| 3 collectors | `into`: forwards, flake outputs | strata 0–2, and `outputs` of targets this branch does not forward into | an eval error: a static check on the collector graph |

`docker`'s `contains ren.user.bob` sits in stratum 0. It reads the same spawn result that put bob there, so it can't drift from the grant rule.

## Expected result (new and changed rows only; v25's other rows stand)

| capability | must appear | must **not** appear |
|---|---|---|
| `fold = one` | `deploy.nodes.lb.hostname = "10.0.1.1"` | `deployment` handed to `into` as a list; two `deployment` emitters on one host evaluating |
| `fold = list` order | lb's haproxy lists web-1, then web-2 (scope-path order), on every eval | order depending on attribute or include order |
| guest channel | ci (`stable`) built with stable pkgs inside stage (`edge`) | ci silently built with stage's `edge` pkgs |
| chained forward | bob's HM in ci → ci's nixos → stage's `microvm.vms.ci.config` | bob's ci home in stage's own `home-manager.users` |
| darwin + `os` | `darwinConfigurations.studio`: hostName, motd, git, dock; alice + bob HM under darwin | studio in `nixosConfigurations` or `colmena`; `kernel` or `impermanence` on studio |
| standalone home | `homeConfigurations.alice-laptop` (edge HM): git, syncthing | ssh-agent in alice-laptop (not `within machine`) |
| host-qualified | htop in alice's home on web-1 only | htop for alice on lb/web-2, or for bob anywhere |
| substitute | web-2 motd = "ren"; others "managed by ren" | both motd values on web-2 (a merge conflict) |
| `contains` | docker on stage and ci (bob lives on both) | docker on prod hosts; docker that tracks a hand-copied grant |
| `parent` | alice's syncthing devices = lb, web-1, web-2, stage, ci, studio, pixel, alice-laptop (minus the scope's own parent) | branching on `host ? null` in content |
| per-system | `packages.{x86_64-linux,aarch64-linux,aarch64-darwin}.hello` | `packages` keyed by host |
| overlays | every machine has the helix overlay | the overlay applied twice on ci (once through stage) |
| impermanence (`set`) | stage persists `/var/lib/nginx`, `/var/lib/docker`, alice's and bob's syncthing dirs, once each | ci's docker dir on stage; a duplicate path |
| name uniqueness | — | `ren.host.ci` and `ren.guest.ci` both evaluating |
| output merge | — | two scopes writing different `nixosConfigurations.lb` evaluating |
| content-function rule | — | a bare `final: prev:` emission evaluating as content |
| hmPlatforms (`homeDarwin`) | aerospace in alice's and bob's homes on studio only | aerospace in any linux, phone or standalone home |
| meta = emission | colmena tags for stage include `web` (nginx emits it) | a `meta` key reserved by Ren |
| flake-file | `flake-file.inputs.{agenix,microvm}` written once, a top-level option beside `nixosConfigurations` | an input listed by a feature that is not active; two features giving `agenix` different urls evaluating |
| recursive `attrs` | `deploy.nodes.{lb,web-1,web-2,stage}` and `colmena.{…}` merged from four host scopes; `agenix = { url; inputs.nixpkgs.follows; }` from two features that agree on `url` | a conflict error between hosts for the top-level `deploy` key |
| `anywhere` | a `flake-inputs` emission from a feature `at = ren.fleet.main` reaches `flake-file.inputs` | root-scope emissions dropped because `within` excludes the root |
| `attrs` in `into` | `packages.x86_64-linux` built from two features' attrsets | two features giving different `hello` derivations evaluating (v27's `mergeAttrsList` kept the last) |
| per-branch stratum 3 | the standalone-home branch reads `outputs.nixosConfigurations.<h>.config` (Den `osConfig`) | the `within host` branch reading `outputs.nixosConfigurations` evaluating: it forwards into `nixos`, so that's a cycle |

> VIC:

## Gen mapping

Read in gen's code at origin/main (gen bcbc5ca, gen-scope adc5180, gen-select 42a09ef, gen-view b3cb176, gen-delivery d4095af, gen-aspects 1847f11, gen-schema 2a9f618, gen-bind 707838a, gen-assemble 4f757c8, gen-settings, gen-graph). Nothing was evaluated.

| Ren construct | gen owner | status |
|---|---|---|
| `spawn`, scope tree | gen-scope `mkKind { spawns; below; }` (lib/cascade.nix) | direct |
| several parents (`any [ spawn … ]`) | gen-scope; one builder, ids minted `parent/child` | glue |
| `is` subtyping | gen-select `subkind` (constructors.nix:154) matches a kind or its ancestors; gen-schema kinds | glue; whether a scope can bind under two kind names is UNVERIFIED |
| `within`, `contains`, `parent` | gen-select `within` / `has` / `parentMatches` (match.nix:122/119/125) | direct |
| `anywhere` | gen-select `star` (constructors.nix, match.nix:100: always true) | direct |
| fold laws as functions in `into` | the same Ren glue as pool folds | glue |
| per-branch stratum-3 check | gen-graph `lib/order.nix` over the collector graph | direct (file exists; not read further) |
| `all any unless`, kind/instance refs | gen-select `and` / `anyOf` / `not` / `kind` / `entity` | direct (renamed) |
| `when f` | gen-select `when` (called `fn id ctx`) | 1-line adapter |
| `same` | gen-schema `id_hash` identity | direct |
| typed strict kinds, ref fields | gen-schema `mkInstanceRegistry`, `mkStrictModule` | direct |
| features, `take`, target vs signal keys | gen-aspects `includes`, `keyCategory` (class vs channel) | direct |
| `omit` | none in gen-aspects; gen-rules `conditionalEdge { unless }` and gen-program `suppress` guard an include | GAP: nothing removes an existing include |
| `has` with stratification, negative-cycle error | gen-program (well-founded and stable-model oracles) | UNVERIFIED |
| signals, pools | gen-view movement works receiver-side over graph paths; emitter-parameterised `to` is a filter | glue |
| `fold` laws | `list` = gen-assemble positional content fold; `set`/`attrs`/`one` not found as named folds | glue |
| `first` cascade | gen-settings `lib/resolve.nix`: positional authority, no strength lattice (:7) | direct, reversed order |
| group closure | gen-graph `lib/fixpoint.nix` | direct (file exists; not read further) |
| target DAG, stratum-3 check | gen-graph `lib/order.nix` | direct (file exists; not read further) |
| content args | gen-bind `wrapAll` with bindings ∪ pools | direct |
| targets → outputs | gen-delivery `project` / `realize`, one terminal per collector | glue |
| forwarding | none; two-pass through gen-delivery's `extraModules` inlet | GAP |

The two gaps, forwarding and `omit`, are where Ren would push gen forward rather than just use it.

## Den coverage

Every user-facing pattern in `~/hk/den/docs/src/content/docs`, read in full by 4 readers this session. Cross-flake namespaces, angle brackets and Den tooling are out of scope.

| Den pattern (doc) | Ren |
|---|---|
| aspect class bundle (`explanation/aspects:21`) | feature with several target keys, `at = any [ … ]` |
| `includes` / nested aspect / `._` children (`guides/configure-aspects:116-225`) | `take = [ … ]`; a group is a plain Nix attrset: `take = lib.attrValues ren.features.editors` |
| inline fn include (`explanation/aspects:52`) | an anonymous feature inside `take`; its module key is `<taker>/<index>` |
| parametric `{ host, user }:` aspect, arg-shape gating (`explanation/parametric:20-67`) | content args = scope bindings; activation is `at`, never the arg shape |
| class module forms `{ host, config, pkgs, ... }` (`explanation/class-modules:25-97`) | content fn args = bindings ∪ pools ∪ module args |
| `excludes`, constraints `exclude`/`substitute`/`filterBy` (`explanation/structural:160-215`) | `omit`; substitute = `omit` + `take` |
| `"tux@igloo"` host-qualified aspect (`explanation/entities:54`) | `at = all [ ren.user.alice (within ren.host.web-1) ]` (`htop`) |
| `provides.to-users`, `provides.<user>` (`guides/mutual:88-91`) | `at = all [ ren.kinds.user (within ren.kinds.machine) ]` (`ssh-agent`) |
| `provides.to-hosts`, `provides.<host>` (`guides/mutual:80-83`) | `at = all [ ren.kinds.host (contains ren.user.bob) ]` (`docker`) |
| `{ user, ... }:` nixos per user on host (`explanation/where-config-lands:168`) | the `user` target (users.users.<name>) or a host feature mapping over the host's users |
| `host-aspects` battery (`reference/batteries:133`) | home feature `at` the user, reading `has F host` in content |
| `hasAspect`, `.forClass`, `host.aspects` (`explanation/structural:28-151`) | `has F x`, `features` |
| `den.hosts` / `den.homes` / per-user `classes` (`reference/schema:108-236`) | kinds; per-user class = a collector `at = all [ user (when (s: lib.elem "hjem" s.user.classes)) ]` |
| schema extend, freeform, `strict` (`explanation/entities:117-251`) | kinds are always typed and strict; freeform is not allowed (by design) |
| `den.schema.<kind>.includes` (`explanation/entities:117`) | feature `at = ren.kinds.<kind>` |
| `den.default` (`guides/configure-aspects:260`) | feature `at = any [ every kind ]` |
| `fleet` grouping kind (`explanation/fleet:244`) | `ren.kinds.fleet` |
| `policy.resolve.to`, `resolve` enrich (`reference/policies:39-53`) | `spawn`; enrich = a kind field or a value computed in `spawn f` |
| `policy.include` / `when` / `for` / `mkPolicy` (`reference/policies:55-274`) | `at` predicates |
| `policy.provide` / `route` / `deliver` / `forward` battery / `forwardTo` (`reference/policies:71-151`) | collector `into` returning a target key (forward) |
| `policy.instantiate`, `intoAttr`, `intoAttr = [ ]` (`reference/output:26-101`) | `into` output keys; no output key = no output (guest) |
| host `instantiate` override, patched nixpkgs (`guides/nixpkgs:243`) | `channel` instance data used by `into` |
| quirk declare / produce / consume (`reference/quirks:14-105`) | `ren.signals` + key emission + pool arg |
| `pipe.filter/transform/fold/append/for/as` (`reference/quirks:140-216`) | plain Nix on the pool, plus signal `fold` |
| `pipe.to [ aspects ]` (`reference/quirks:297`) | `to = e: all [ … (has F) ]` |
| `pipe.collect` / `collectAll` / `broadcast` / `expose` (`guides/quirks-cross-scope:89-361`) | `to` predicates: same env / any / same instance / ancestor (`to = e: e.host`) |
| `pipe.withProvenance` (`reference/quirks:321`) | emit the source in the value (`{ name; addr; }`) |
| quirk `{ config, ... }` producer thunk (`explanation/quirks:237`) | **not allowed in content.** Read realized config only in `into` through `outputs` (stratum 3). |
| settings: reservedKeys, required, mkDefault/mkForce, user settings (`guides/aspect-settings`) | `settingsT` per kind; no default = required; module priorities inside the instance |
| collision policy `den-wins`/`class-wins` (`reference/aspects:185-224`) | NixOS module merge. Pool and binding names must not clash with module args: eval error |
| batteries: define-user, hostname, primary-user, user-shell, unfree, insecure, autologin, wsl (`reference/batteries`) | ordinary features shipped by a library; nothing special in Ren |
| `os`, `user`, hjem, maid, custom classes (`guides/custom-classes`) | targets; `os` is a collector list (host, mac) |
| flake outputs per system: packages/apps/checks/devShells, `flake` class (`guides/flake-outputs`) | `system` kind + `packages` collector (`tools`) |
| ACL environments (`guides/acl-environments`) | `group` kind + `closure` + `granted` |
| overlays, `useGlobalPkgs`, unstable channel (`guides/nixpkgs`) | `channel` kind; overlays = a signal, gated by `when` on the receiver |
| standalone home, `user@host` home (`guides/standalone-home-manager`) | `home` kind + `homeManager` branch (`alice-laptop`) |
| microvm `resolve` + `provide` (`tutorials/microvm:145-186`) | `guest` kind (`is = host`) + guest collector forward |
| terranix / k8s `instantiate` (`tutorials/terranix-demo`, `case-study-kubernetes`) | value-gated collector; a cluster kind + collector per system |
| impermanence persist collector (`tutorials/case-study-disks-impermanence:280-352`) | `persist` signal, fold `set` (`impermanence`) |
| `meta`, fixed-point `config` self-ref (`guides/configure-aspects:290-365`) | Nix `let`/`rec` in the feature's file |
| nh apps, diagrams, policyInspect, denTest, import-tree | tooling, out of Ren's scope |

## Den templates and CI tests vs Ren

Sources: every `.nix` file in `~/hk/den/templates`, read in full by 9 readers (all report 100% coverage):
- 13 templates, 154 files;
- CI, 288 files.

The table lists only patterns not already in **Den coverage** above.

| Den pattern (source) | Ren |
|---|---|
| hmPlatforms, hmAlias (`ci/…/hm-platform-forward.nix:22`, `forward-alias-class.nix:5`) | sub-target collector forwarding in place (`homeDarwin`); HM's own `osConfig` arg |
| roleClass: a key named after a role, applied when host and user share it (`guides/custom-class-examples:109`) | `ren.targets = lib.genAttrs roles (r: { at = all [ ren.kinds.user (when (s: shares r s)) ]; into = { ... }: ms: { nixos.imports = ms; }; })` |
| nixClass: one key to nixos and homeManager `nix.settings` (`custom-class-examples:166`) | a collector list with two branches forwarding to `nixos.nix.settings` and `homeManager.nix.settings` |
| guarded forward, persys, gitClass: guard on `options ? x` or `config.programs.git.enable` (`ci/…/guarded-forward.nix:24`, `route-intopath-conditional-leak.nix:42`) | guard in stratum 0/1 (`at`, `has`), or `lib.mkIf cond value` around a config *value* inside the target. **Not** `options ? x` around a module: `imports` cannot depend on `options`/`config` (the module system recurses), and `m` is usually a function |
| `deliver` modes merge / nest / verbatim, dynamic `intoPath` (`ci/…/deliver.nix:46-247`, `dynamic-intopath.nix:5`) | what `into` returns: `ms` as imports (merge), under a path (nest), or into a sub-eval (verbatim, as the guest does) |
| isolated entity + `collectSubtree` + `appendToParent` (`ci/…/route.nix:211`, `entity-isolation.nix:42`) | guest kind + guest collector; nothing leaks, because content lands only in its own scopes |
| microvm runners, nvf packages from a parametric aspect (`microvm/microvm-runners.nix:10`, `nvf-standalone/…/den.nix:13`) | a `packages` collector; a feature is a value: `take = [ (neovim { mine = true; }) ]` |
| terranix modules per host, flake-parts classes devshell/files/treefmt/nix-unit (`terranix-demo/…/terranix.nix:23`, `flake-parts-modules/…/classes/*.nix`) | one collector each; `into` writes the top-level option (`devshells.default`, `files`, `nix-unit.tests`) |
| home `instantiate` with the host's `osConfig` (`ci/…/special-args-custom-instantiate.nix:6`) | the standalone-home branch reads `outputs.nixosConfigurations.<h>.config` (stratum 3). Legal only because the check is per branch: the `within host` branch forwards into `nixos` |
| `user@host` home synthesizes a host (`ci/…/standalone-home-host-context.nix:40`) | `home.on = maybe ren.kinds.host`; `when (s: same s.home.on ren.host.x)` |
| relationship fan-out `{ user, pet }`, transitive `{ pet, toy }` (`ci/…/relationship-fanout.nix:343,431`) | kinds `pet` (spawn under host) and `toy` (spawn under pet); a feature `at = ren.kinds.toy` binds `pet` and `toy` |
| per-user parametric content stays per user; static content shared (`ci/…/issue-644-parametric-host-forward-per-user.nix:35`) | a feature at user scope fires once per user scope; module key `<feature>@<path>` |
| chained forward classes (`ci/…/issue-645-chained-forward-classes.nix:41`) | forwards chain (target → target → target), acyclic |
| same aspect in host and user schema includes, once per scope (`ci/…/relationship-fanout.nix:291`) | `at = any [ host user ]`: one firing per scope |
| identical values merge, different values error (`ci/…/issue-674-identical-values-merge.nix:14`, `instance-collection-merge.nix:127`) | the `attrs` law for outputs and pools |
| named inline include identity, shared raw include dedup (`ci/…/nested-key-wrapper-identity.nix:221`, `shared-raw-include-splits.nix:17`) | module key `<feature>@<scope path>`; an anonymous feature in `take` is keyed `<taker>/<index>` |
| exclude by string rejected (`ci/…/excludes-string-form-rejected.nix:13`) | `omit` takes refs only; a string is a type error |
| exclude naming a feature that never fires: a warning (`ci/…/unmatched-policy-exclude.nix:29`) | the same warning: an `omit` that removes nothing |
| quirk named like a class (`den.quirks.nixos`): throws (`ci/…/pipes.nix`) | target and signal names are disjoint: eval error |
| `den.schema.conf`: options on every kind (`ci/…/doc-examples.nix:6`) | a shared `let` field set merged into each kind, or an abstract kind with `is` |
| enrich context with a flag (`isNixos`) via `policy.resolve` (`ci/…/policy-context-enrichment.nix:8`) | a kind ref (`ren.kinds.host` vs `ren.kinds.mac`) or a `let` predicate |
| `{ self, ... }` fires once at its registration scope (`ci/…/self-guard.nix:13`) | `at = ren.host.igloo` (instance ref) |
| noflake entry, npins, with-inputs (`noflake/default.nix:1`) | `ren.lib.mkFlake` is a module set; `evalModules` it without a flake |
| `systems = builtins.attrNames den.hosts` (`fleet-demo/…/flake-parts.nix:4`) | `ren.system` instances |
| `includeIf` with fallback (`ci/…/fx-includeIf.nix:180`) | `a = { at = all [ K (has sops) ]; … }; b = { at = all [ K (unless (has sops)) ]; … }` |
| exclude subtree vs `.global`, `filterBy` (`ci/…/fx-constraints.nix:266-688`) | `omit` is subtree; global = an `omit` on a feature `at = ren.fleet.main`; filterBy = `omit = lib.filter p (lib.attrValues ren.features)` |
| `_module.args.host` colliding with a den arg; `collisionPolicy` (`ci/…/class-module-partial-apply.nix:437-535`) | a binding or pool name clashing with a module arg is an eval error; no policy knob |
| custom class with no route: throws (`ci/…/forward-to.nix:123`) | a key that names no target or signal: eval error |
| class key as a list of modules (`ci/…/fx-full-pipeline.nix:247`) | content may be a list; each element is one module in `ms` |
| den as a library with a custom domain (`ci/…/den-as-lib.nix:62`) | Ren's kernel has no domain names: targets and kinds are all user-declared |
| flake-level forward, per-host parametric packages (`ci/…/forward-flake-level.nix:5,166`) | a host collector writing `packages.${system}.${"sw-" + host.name}` (attrs law merges hosts) |

### Den behaviours Ren refuses (by design)

| Den behaviour (source) | Ren instead |
|---|---|
| quirk value `{ config, ... }:` reads the producer's realized config, even cross-host (`ci/…/pipe-config-scope.nix:11`, `bprime-basedrain-crosshost.nix:39`) | content never reads config; read realized config only in `into` via `outputs` (stratum 3) |
| misplaced entity arg (`{ gadget, ... }:` with no gadget) is silently inert (`ci/…/relationship-fanout.nix:128`) | activation is `at`; a content arg with no binding is an eval error |
| homeManager content at host scope is silently inert (`ci/…/issue-609-host-scope-hm-leak.nix:17`) | an error if it lands in none of the feature's scopes |
| `hasAspect` inside `includes` is an infinite recursion (`example/…/hasAspect-examples.nix:109`) | `has F` in `at` is stratified; a cycle is a named eval error |
| `policy.resolve.shared` vs isolated scopes, `mkPolicy` claimants (`ci/…/policy-resolve-shared.nix`) | no policies: `spawn` makes scopes, predicates select |
| namespaces, angle brackets, import-tree, diagrams, denTest | outside Ren (gen-link, tooling) |

## Den feature requests vs Ren

Sources:
- denful/den: 19 open issues, read in full; 149 open discussions, with Ideas read in full and Help/FAQ skimmed.
- `~/Downloads/el.txt`, the Matrix log: **read in full**, all 35 390 lines, by 12 readers.

`#N` is an issue or discussion; `L<line>` is a Matrix log line. Repeats are merged.

### Already expressible in Ren (no change)

| ask | Ren |
|---|---|
| per-feature flake inputs: #348, #336, L17109, L20140, L21482, L33338, L33346; fetch only active features' inputs: L20814 | `flake-inputs` signal + `flake-file` collector. The regenerated `flake.nix` lists only active features' inputs; activation changes need a regeneration step |
| user content must not change the shared host: #694; host app → all users vs user app → one user: L535, L4888, L5655, L29994 | no provides-to; content lands only in the feature's own scopes; `within` / `contains` |
| host↔user both ways, opt-in: #450, L1110, L1857, L5676, L6802, L7509, L18917, L18929, L25830, L25875, L27963, L28063 | predicates: `within`, `contains` (`ssh-agent`, `docker`, `htop`) |
| hmLinux / hmDarwin / hmAarch64 forwards: L26816, L34138, L34189, L34191 | a sub-target collector forwarding in place (`homeDarwin`) |
| aspect metadata, tags: L5141, L28728, L28734, L28835 | `meta` is just an emission (fold `set`); `deployment.tags = meta` |
| `den.hosts.<h>.includes` dropped: #663; `include` typo silent: L14871; early shape errors: L27758, L35195, L31077 | strict kinds; a key that is not a target or signal, or lands nowhere, is an eval error |
| `os` to systemManager: #718; finix: #662; disko: L30402; timezone for nixos+darwin: L24576 | an `os` collector branch; a collector per builder |
| nix-on-droid: #517; terranix, per-host plan/apply: #115, L9418, L15871, L16194, L16263 | `droid` target; `terraform` collector (env or host) |
| custom entity kinds, k8s clusters, identities, domains: #701, L1233, L1312, L7046, L9659 | `ren.kinds.*` + a collector |
| service discovery, vhost → proxy, contributes-to, host A reacts to host B: L1241, L1891, L3626, L8626, L8666, L8718, L10555, L10638, L13153, L14353, L15580, L22851, L17277, L26453, L28072 | signals with `from`/`to` predicates; `has F x` |
| `hasAspect` presence, include when A and B: L2011, L4753, L4759, L4804, L19798, L20902, L25924, L27618, L28376 | `has F` in `at` (stratified), `has F x` in content |
| `includedBy`, leaf-to-root membership, of.host: L16608, L18542, L25436, L33967 | that is what `at` is |
| relation that is not an instantiation: L25801 | signals and predicates never spawn; only `spawn` creates scopes |
| exclude an inherited aspect / default on one host or user: L1432, L18502, L21348; variant swap: L1434 | `omit`; substitute = `omit` + `take` |
| one default for host users and standalone homes: #205, L1513; `user@host` homes: #206, L12497, L24023, L26159, L26610 | `at = ren.kinds.user`; the `home` kind, plus a field `on = maybe host` |
| impermanence per aspect: #590, L23751, L31027 | `persist` signal (fold `set`) + `has` |
| recursive groups, ACL, admin groups from other aspects: L1316, L9646, L27846, L28483 | `group` kind + `closure`; a `groups` signal |
| global include (sops everywhere): L1244; stateVersion battery: L452 | a feature `at = ren.kinds.machine` |
| register a user on all hosts, users first-class: L18763, L18807, L19693, L26396, L29019, L30697 | user `spawn f` over `ren.user`; the user kind is host-independent |
| list a host's users, sync users: L32162, L33144 | `contains ren.kinds.user`, or a signal `to = e: e.host` |
| shared options for nixos + HM, context config from anywhere: L1167, L3370, L3403, L3454, L30900 | kind fields read through bindings (`host.settings`, `user.*`) |
| per-feature settings namespace: L6027, L25261; package-typed options: L8355, L8468, L28282 | `settingsT`; a field `t.functionTo t.package` |
| per-host channel, patched nixpkgs: L30125, L30448, L30542; per-aspect pkgs: L1640, L4487, L4549, L4584, L13086 | the `channel` kind; content may close over another channel's pkgs |
| lib/inputs/self'/custom args anywhere: L1669, L9955, L9960, L9986, L11728, L13070, L13096, L13255, L24963, L24975, L30247, L32095 | content args = bindings ∪ pools ∪ module args; `inputs` is in scope |
| devshell, emacs and maid-list classes, adapters: L858, L4726, L5968, L6528, L6770, L7330, L18218, L32123 | a collector whose `into` maps `ms` into any option |
| one `pkgs` aspect adapting by include site: L23078; per-host package subsets: L23310 | a `pkgs` collector list (host → systemPackages, user → home.packages); `take` subsets |
| glob / all children: L14184, L14194, L14212, L14214, L20718, L20743, L21711 | `take = lib.attrValues ren.features.<group>` |
| colmena, deploy-rs, nh target, fleet deploy: L15847, L15851, L15855, L22308, L24606 | `deployment` signal (fold `one`) read by several collectors |
| quirks into a fleet file, custom top-level outputs: L24456, L32574, L32688 | a signal `to = _: ren.fleet.main` + a collector |
| checks class, terraform validate: L32201, L32305, L32410 | a `checks` collector at `system` |
| secrets declared per aspect, agenix secrets.nix: L21088, L32512, L32515 | a `secrets` signal to the fleet + a collector writing the file |
| osConfig of hosts from the flake level: L20831, L21752 | `outputs` (stratum 3) |
| config invariants across hosts: L22634; assert/throw accounts: L32175 | a fleet collector reading pools or `outputs` and throwing |
| deterministic ids, ports, IPs: L19799, L19824, L19834, L19859, L19990 | a `let` allocator over sorted `ren.<kind>` names (stratum 0); a collision is an eval error |
| one host in two fleets: L15822 | the same instance on two spawn paths (`any [ spawn … ]`) |
| per-system outputs from one host (vm): L26519 | a host collector returning several outputs |
| specialisations, vmVariant-only config: #691, L18129, L18725 | a `variant` kind under host + a collector forwarding to `nixos.specialisation.<n>.configuration` |
| dedup when two users include the same nixos: L4877; dedup by args: L6414; provenance: L24628 | module key `<feature>@<scope path>`; `attrs` merge law |
| registry vs activation, policies as values, composition, order-insensitive: L9197, L11117, L14482, L14758, L14790 | refs are values; `all any unless`; `at` activates; folds are order-free (except `list`, by scope path) |
| shared predicates, typed guards (isDarwin): L12577, L12590, L18476 | `let` predicates (`metal`); kind refs (`ren.kinds.mac`); typos are eval errors |
| reuse existing nix modules as features: L16853 | `nixos = import ./hardware.nix;` |
| `pipe.to` an entity, pipe default, `pipe.as`: L15095, L15097, L17329 | `to` predicate; empty pool; a feature emitting a new signal |
| drop `each` from forward: #476; vic's wishlist L752-761 | a forward is a returned key |

### Possible, but Ren would need a change

| ask | change needed |
|---|---|
| patch an attr of a third-party feature or its output before merge: #443, L4923, L6072 | an override form `ren.features.x.override = f`; `omit` + `take` covers only whole-feature swaps |
| nested feature groups (`dev.cli.bat`) without `provides`: L5146, L5153, L5280, L6019, L19401 | a rule telling a group (no target, signal or reserved keys) from a feature |
| one feature defined in several files, content fns included: L11448 | a merge law for content functions (merge their results) |
| a schema on signal values: L30891 | a signal `type` key, checked at emission |
| use Ren features outside Ren: #569 | `ren.lib.moduleOf feature scope` |
| priority by specificity (`tux@igloo` over `tux`): #686 | instance ref > kind ref, mapped to `mkOverride` |
| option docs from the kinds: L9533 | a collector that reads `ren.kinds` as data |
| explain, trace and inspect resolution: #103, L8976, L12332, L14679, L14726, L21366, L31082, L31202 | an inspector over the strata (why active, where landed) |
| diagrams, TUI, web UI, LSP, SQL over infra: L1541, L3558, L10982, L16878, L20897, L24400, L28676 | tooling over the same strata data |
| namespaces, batteries store, versioning, many projects: #158, #538, L10726, L10857, L11570, L28716, L29049 | gen-link (cross-flake), deferred |

### Not in Ren, by design or outside its reach

- Declaring a host's users inside a feature (L33868): existence is `spawn`, stratum 0.
- Real-host config from a standalone home (L1857): a home has no host scope.
- Clan interop (L176, L22344), angle brackets and import-tree headers (L15404, L18008, L20961): external or tooling.
## Open

- **`machine` adopted (vic, v26).** It is the abstract kind for darwin and the `os` class; `host` and `mac` are its subtypes.
- **`parent` vs naming the kind.** `parent` makes `devices` one line, but a feature that needs "the host" specifically should still bind `host`. `parent` is for code that is generic over parent kinds.
- **Overlay on guests.** ci gets `nixpkgs.overlays` from `base` inside its own config, and its pkgs come from its channel. Whether microvm's `vms.<n>.pkgs` composes with the guest's `nixpkgs.overlays` is a microvm.nix question, not checked.
- **Den items still not shown:** namespaces from another flake (gen-link), per-user classes (hjem/maid), wsl. Each is a target plus a predicate; none needs new surface.
