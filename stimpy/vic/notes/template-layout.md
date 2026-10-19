# templates/fleet layout — aspect-oriented, loaded by import-tree (2026-10-19, opus-5-5)

Goal: Ren uses this SAME layout. Copy tree + rules below. Only `ren.lib` impl differs (Gen vs nixpkgs.lib).

## Rules

1. NO manual imports. `flake.nix`: `outputs = inputs: inputs.stimpy.lib.mkFlake inputs (inputs.import-tree ./modules);`
   input `import-tree.url = "github:denful/import-tree"`. Every `.nix` under `modules/` = one module. Path `/_` = ignored (import-tree default).
2. File = ONE concern (aspect), NOT one implementation type. A concern file holds ALL parts it needs:
   kinds + instances + classes + channels + aspects. Example `features/web.nix` = channel `backends` + aspects `nginx haproxy http-port web`.
   Den: "aspects (features) are the primary organizational unit" (den docs explanation/core-principles.mdx:158).
3. Filesystem = free. Dir names are for humans only. Move/rename a file ⟹ zero code change. Evaluation never reads paths.
4. Shared helper ⟹ the concern that owns it publishes it: `_module.args.<name> = …`. Consumer takes it as a module arg `{ metal, ... }:`.
   Den precedent: `templates/example/modules/namespace.nix:14` `_module.args.__findFile = …`. Helper used by 1 file ⟹ private `let` in that file.
5. One key = one file. `ren.{kinds,classes,channels,aspects}.<name>` are `lazyAttrsOf raw` (lib/view.nix): different names merge across files; SAME name in 2 files = error. Instances `ren.<kind>.<name>` are deferredModule ⟹ may merge (not used yet).
6. Definitions move WHOLE. Split never changes an aspect/class/channel/kind. fleet.md stays the law; layout is not semantics.

## Tree

```
modules/
  helpers.nix                 args: opt maybe
  topology/                   the scope tree
    fleet.nix                 kinds fleet system; fleet.main; systems
    channel.nix               kind channel; channel stable edge; args: pkgsOf
    environments.nix          kind environment (spawns via inEnv); env prod staging
    access.nix                kinds group user; groups ops admin deploy; args: usersOn (group closure ∩ env grants)
    machines.nix              kind machine (abstract); aspect base; args: metal
  platforms/                  one module system each: class + its kind + its defaults
    nixos.nix                 class nixos (metal + guest branches); kind host
    microvm.nix               kind guest; aspects vm vm-host
    darwin.nix                classes darwin homeDarwin; kind mac; aspects dock tiling
    os.nix                    class os
    home-manager.nix          class homeManager (4 branches); kind home; aspects hm-module hm-state hm-standalone
    droid.nix                 class droid; kind phone
  hosts/                      one file per machine instance + aspects only that machine activates
    lb.nix (aspect lb) · web-1.nix · web-2.nix (aspect quiet) · stage.nix (aspect desktop) · ci.nix · studio.nix · pixel.nix
  users/                      one file per user + aspects keyed on that user
    alice.nix (home alice-laptop, aspect htop) · bob.nix (aspect docker)
  features/                   cross-cutting concerns
    web.nix                   channel backends; aspects nginx haproxy http-port web
    monitoring.nix            kinds db region replica + instances; channel scrape; aspects replica-scrape monitoring
    deploy.nix                channels deployment meta colmena; aspect deploy-record
    secrets.nix               channel age-manifest; aspect secrets
    dns.nix                   class terraform; channel records; aspect dns
    impermanence.nix          channel persist; aspect impermanence
    kernel.nix                args: settingsT; aspect kernel
    sync.nix                  channel devices; aspect sync
    overlays.nix              channel overlays; aspect unstable-overlay
    packages.nix              channel packages; aspect tools
    flake-inputs.nix          channel flake-inputs
    dev.nix · ssh-agent.nix · motd.nix (motd motd-short)
```

Args graph (who publishes ⟶ who reads):
`opt maybe` helpers ⟶ topology, kernel · `pkgsOf` channel ⟶ nixos home-manager droid · `metal` machines ⟶ nixos microvm deploy secrets impermanence · `usersOn` access ⟶ nixos microvm darwin · `settingsT` kernel ⟶ environments machines.

## Placement test (where does a new thing go?)

- Activates on ONE named machine/user ⟹ `hosts/<m>.nix` / `users/<u>.nix`.
- Defines a module system ⟹ `platforms/<class>.nix` (with its kind).
- Shapes the scope tree ⟹ `topology/`.
- Else (cross-cutting) ⟹ `features/<concern>.nix`, with its channels.

## Tests

- tier1 `templates/fleet/tests/default.nix`: `fleet = import-tree ../modules`; suites = `(import-tree.withLib lib).filterNot (hasSuffix "/default.nix")).leafs ./.` ⟹ one suite per file. Helper data = `_ids.nix` (`/_` ⟹ not a suite).
- import-tree for tier1 = template `flake.lock` node `import-tree` via `builtins.fetchTree`, read INSIDE `templates/fleet/tests/default.nix`. Template owns the dep.
- e2e `tests-e2e/default.nix`: `mkFlake inputs (inputs.import-tree ../modules)`; `e2e.nix` lock-walk builds `import-tree` like any node.
- Split oracle (one-shot, scratchpad): `evalFleet` old `fleet.nix` vs `import-tree ./modules` ⟹ same scopes/active/landed/emitted/branches/output names; neg control (drop motd.nix) ⟹ eval error.

## stimpy itself (lib + tests) — nest pattern, deps = nixpkgs only

Copy of `~/hk/nest/default.nix` + `tests.nix`. NO import-tree outside `templates/fleet`.

- `lib/<name>.nix` = `stimpy: { <name> = …; }`. Arg is plain `stimpy:` (NO `{ lib, … }:` destructure: it forces the fixpoint ⟹ infinite recursion). Deps via `inherit (stimpy) lib pred;` in the file top `let`.
- Cross-file calls: `stimpy.scopes { … }`, `stimpy.kinds cfg kinds`. No `import ./x.nix`.
- `default.nix`: `stimpy = foldl' (acc: f: acc // import (./lib + "/${f}") stimpy) { inherit lib; } files` over `readDir ./lib`; returns `removeAttrs stimpy [ "lib" ]`.
  Exports: activation branches collect content evalFleet folds kindgraph kinds merge mkFlake pools pred scopes view.
- `tests.nix`: `lib` = one suite per `tests/*.nix` (name = file name; `_` prefix = helper, e.g. `_vocab.nix`); `templates` = `import ./templates/fleet/tests`. Justfile: `import ./tests.nix`.
- Unit tests reach internals as `stimpy.view`, `stimpy.pred`, `stimpy.merge`, `stimpy.folds`.
- Ren: same shape; `ren/lib/<name>.nix` = `ren: { <name> = …; }` (Gen input instead of nixpkgs).
