# Ren & Stimpy

![ren](ren-and-stimpy.gif)

Ren is a small surface language for aspect-oriented, context-driven Nix fleets.
Ren was [designed](vic/fleet.md) by [vic](https://github.com/vic) and is inspired by [Den](https://github.com/denful/den).
If you know Den, you know the ideas. Ren gives them a smaller grammar.

- [Ren](ren) is built only on [Gen](https://github.com/sini/gen) (`github:sini/gen`).
  Its purpose is to be our first attempt to model the same capabilities of Den on Gen.
- [Stimpy](stimpy) implements the same [specification](vic/fleet.md) only on `nixpkgs.lib`.
  We use it to compare Gen with `nixpkgs.lib`.
- Both run one shared fleet template. Ren knows nothing about hosts, users or NixOS:
  you declare your own domain, and Ren wires it together.


Ren is _NOT_ the next version of Den, it is simply a step forward into making sure we
can use Gen to implement all of Den capabilities.

## The grammar

- **kinds**: the types in your domain. A parent kind lists its child kinds in `below` and picks them with `spawns`.
- **instances**: the named things of a kind, as `ren.<kind>.<name>`.
- **classes**: module systems that receive configuration, with `at` and `into`.
- **channels**: data that flows from emitter scopes to receiver scopes, with a `fold`.
- **aspects**: units of configuration. `at` activates them in matching scopes.

Reserved words (`vic/fleet.md`, "Reserved words, v29.A"):

| group | words |
|---|---|
| keys | `at into below spawns is to fold includes excludes` |
| predicates | `and anyOf not when within has is same` |
| folds | `list set attrs one` |
| bindings | `parent outputs` |

A kind, instance or aspect reference is also a predicate. `at` means "which scopes" on every noun.

## Advanced parts, one at a time

All snippets come from the tested [Fleet template](ren/templates/fleet/modules) which was based
on Den capabilities and some other advanced usage patterns from [sini's nix-config](https://github.com/sini/nix-config).

Remember that unlike Den, Ren has no NixOS nor other specific domain knowledge. 
All kind names like `environemnt`, `host`, `mac`, are specific to our Fleet template but you can use
whatever nouns work best to your problem modeling.

When reading these examples it would be helpful to read the corresponding nix files.

### A scope tree from `below` and `spawns`

An environment spawns the machines that name it:

```nix
ren.kinds.environment = {
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
```

Each machine kind spawns its users with `spawns.user = usersOn`. A user lands on a machine
when a group in its group closure is granted by the environment (`topology/access.nix`).
alice is in `ops`, `ops` is a member of `admin`, and `prod` grants `admin`.
In Den you write a policy for each edge (`to-fleet`, `fleet-to-envs`, `env-to-hosts`,
`env-users`) and attach each one with `den.schema.<kind>.includes`.

### Predicates as `at`

```nix
_module.args.metal = and [
  ren.kinds.host
  (not ren.kinds.guest)
]; # physical nixos hosts

ren.aspects.vm-host = {
  at = and [
    metal
    (has ren.kinds.guest)
  ];
  nixos.imports = [ inputs.microvm.nixosModules.host ];
};
```

`metal` is a plain value. `has` matches a scope with a matching child. `within` matches a
scope with a matching ancestor: `htop` uses `at = and [ ren.user.alice (within ren.host.web-1) ]`.
In Den you select scopes with policies and `den.schema.<kind>.includes`. In Ren, every
selection is one `at` predicate.

### `includes` and `excludes`

```nix
ren.aspects.quiet = {
  at = ren.host.web-2;
  excludes = [ ren.aspects.motd ];
  includes = [ ren.aspects.motd-short ];
};
```

web-2 drops the default motd and takes the short one. Den has the same pair. In Ren,
`excludes` is an aspect key, and it works in the aspect's scopes and their subtrees.

### Channels with folds

```nix
ren.channels.backends = {
  fold = ren.lib.fold.list;
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
```

`nginx` emits `backends = { host, ... }: host.addr;`. `haproxy` reads `backends` as an
argument. The receivers are the other hosts in the same environment that do not run nginx.
`deployment` uses `fold = one`: each metal host gets exactly one deployment record.
In Den you declare a quirk, write a policy with `pipe.from` and `pipe.collect`, and include
that policy on every host. In Ren, `to` is the collect rule and `fold` is the merge rule.

### Forwarding classes

```nix
ren.classes.os = [
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
```

When `into` returns a key that names a class, Ren forwards the modules to that class.
A guest forwards to its host as `nixos.microvm.vms.${guest.name}`. `homeManager` has four
branches: in a host, in a mac, in a phone, and standalone.
In Den you use forward, provide or route policies for this. In Ren, a forward is a key in `into`.

### Channel collectors with `into`

```nix
ren.channels.colmena = {
  fold = attrs;
  at = metal;
  to = _: ren.fleet.main; # fed by the nixos collector
  into = { ... }: nodes: {
    colmenaHive = inputs.colmena.lib.makeHive (
      { meta.nixpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; } // nodes
    );
  };
};
```

The `nixos` collector emits `colmena.${host.name}` for each metal host. The fleet folds them
into one hive. Flake `packages` work the same way, one pool per `system` scope.
In Den you choose outputs with `policy.instantiate` and `intoAttr`. In Ren, a data collector
is a channel with `into`.

### Function kinds

```nix
ren.kinds.db.zone = lib.types.str;
ren.kinds.region.zone = lib.types.str;
ren.kinds.replica = { db, region }: when (s: s.db.zone == s.region.zone) { };
```

A kind can be a function of other instances. `when` guards it: a replica exists only where
its db and region share a zone. Each replica sends a prometheus scrape target to `lb`.

**Strata.** Ren evaluates in four strata: scopes, activation, content, collectors (`vic/fleet.md`).
A negative cycle through `not` or `excludes` is an eval error. A content cycle is infinite
recursion, never a wrong value.

## How Ren maps to Gen

| Ren construct | Gen owner | status |
|---|---|---|
| `below` / `spawns` | gen-scope `mkKind { name; below; spawns; }` | direct |
| `and anyOf not`, refs | gen-select `and` / `anyOf` / `not` / `kind` / `entity` | direct |
| `within`, `has`, `parent` | gen-select `within` / `has` / `parentMatches` | direct |
| `when f` | gen-select `when` | 1-line adapter |
| `is` subtyping | gen-select `subkind` | glue |
| `same` | gen-schema `id_hash` | direct |
| typed strict kinds | gen-schema `mkInstanceRegistry`, `mkStrictModule` | direct |
| aspects, `includes`, class vs channel keys | gen-aspects `includes`, `keyCategory` | direct |
| channels with `into` | gen-delivery `realize` | glue |
| group closure | gen-graph `lib/fixpoint.nix` | direct (file exists; not read further) |
| `excludes` | none | gap |
| forwarding | none | gap |

Rows come from "Gen mapping" in [`vic/fleet.md`](vic/fleet.md). Ren pushes Gen forward at the gaps.

## Usage

```nix
outputs = inputs: inputs.ren.lib.mkFlake inputs (inputs.import-tree ./modules);
```

Stimpy uses the same line with `inputs.stimpy` ([template](stimpy/templates/fleet)).
Put one concern in each file:

```
modules/
  topology/   fleet, environments, machines, access, channel
  platforms/  nixos, darwin, droid, home-manager, microvm, os
  hosts/      lb, web-1, web-2, stage, ci, studio, pixel
  users/      alice, bob
  features/   web, deploy, dns, sync, kernel, monitoring, ...
```

## Status and testing

Stimpy runs the template: tests 208/208, e2e 23/23. The Ren port to the shared template is
in progress. Run all checks at the repository root:

```
nix-shell -p just --run 'just ci'
```
