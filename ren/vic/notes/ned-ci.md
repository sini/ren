# ned CI: nix-unit (lib + template level)
Src: /home/vic/hk/ned (read-only). Scope: Justfile, flake.nix, default.nix, .github/workflows/test.yml, templates/ci/*.

## LAYOUT
```
/home/vic/hk/ned/
  Justfile                       (test recipe :14-15)
  flake.nix                      (lib = import ./.; flakeModule)
  default.nix                    (lib entry; locked inputs via with-inputs.nix)
  shell.nix                      (pkgs.nix-unit)
  .github/workflows/test.yml     (runs `just ci`)
  templates/ci/
    flake.nix                    (template flake; inputs incl. ned.url = "github:denful/ned")
    outputs.nix                  (evalModules, import-tree ./modules)
    tests.nix                    (exposes .tests)
    with-inputs.nix              (fetches with-inputs from flake.lock)
    ned.nix                      (ned lib from local ../..)
    modules/default.nix          (declares options.flake.tests, options.ci)
    modules/tests/kernel/{run-tests.nix,st-tests.nix}
    modules/tests/nixos/basic.nix
    modules/tests/nixos/fleet-demo/{default,tests,main-c,...}.nix (16 files)
    modules/tests/readme/{hello-world,dependency-injection,nested-cycles}.nix
```
Not in ned: `gen` (no hits, see GEN INPUT).

## CMDS
Justfile:7-9 (verbatim):
```
ci:
  just fmt --ci --no-cache
  just test
```
Justfile:14-15 (verbatim):
```
test suite="all" *args:
  nix-unit --expr 'let x = import ./templates/ci/tests.nix; in if "{{suite}}" == "all" then x else x.{{suite}}' {{args}}
```
Justfile:11-12 (verbatim, noflake, not test):
```
noflake attr="nixosConfigurations.igloo.config.system.build.toplevel" *args:
  cd templates/noflake && nix-build --no-out-link --arg ned 'import ../ci/ned.nix' ./default.nix -A {{attr}} {{args}}
```
test.yml:21-22 (verbatim):
```
      - uses: actions/checkout@v6
      - run: nix-shell ./shell.nix --run 'just ci'
```
Other: `just test <suite>` selects `x.<suite>` (e.g. kernel, nixos, readme). Not verified beyond the recipe text.

## NIX-UNIT WIRING
Lib entry, flake.nix:1-10 (verbatim):
```
{
  outputs = _: {
    lib = import ./.;
    flakeModule =
      { lib, inputs, ... }:
      {
        _module.args.ned = import ./. { inherit lib inputs; };
      };
  };
}
```
default.nix:1-10 (verbatim):
```
let
  locked = import ./templates/ci/with-inputs.nix { };
in
{
  inputs ? locked,
  lib ? (inputs.nixpkgs or locked.nixpkgs).lib,
  fx ? import (inputs.nix-effects or locked.nix-effects) { inherit lib; },
  ...
}:
import ./kernel.nix { inherit lib fx; }
```
templates/ci/tests.nix:1 (verbatim):
```
(import ./with-inputs.nix { ned.outPath = ../..; } ./outputs.nix).tests
```
templates/ci/outputs.nix:1-5 (verbatim):
```
inputs:
(inputs.nixpkgs.lib.evalModules {
  modules = [ (inputs.import-tree ./modules) ];
  specialArgs.inputs = inputs;
}).config.flake
```
templates/ci/modules/default.nix:7-18 (verbatim):
```
{
  imports = [ inputs.ned.flakeModule ];

  config._module.args.ci = config.ci;

  options.flake.tests = lib.mkOption {
    description = "nix-unit tests";
    default = { };
    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.unspecified);
    };
  };
```
Collection: import-tree ./modules auto-imports every .nix under modules/. Attr shape = `flake.tests.<group>.<name>` (two-level lazyAttrsOf). Test name prefix convention `test-` (e.g. `test-basic`, `test-hello-world`, `test-no-driver`). Each leaf = `{ expr; expected; }`.

Sample leaves (verbatim):
templates/ci/modules/tests/readme/hello-world.nix:36-37
```
in
{
  flake.tests.readme.test-hello-world = { inherit expr expected; };
```
templates/ci/modules/tests/kernel/run-tests.nix:7-15
```
  flake.tests.kernel.run = {
    test-no-driver = {
      expr =
        let
          sinks = ned.run { } (_: ned.st { hello = "world"; });
        in
        sinks.toList;
      expected = [ { hello = "world"; } ];
    };
```
templates/ci/modules/tests/nixos/fleet-demo/tests.nix:16-21
```
  flake.tests.nixos.fleet-demo.test-lb-prod-haproxy-backends = {
    expr =
      lib.hasInfix "10.0.0.2:8080" lb-prod.services.haproxy.config
      && lib.hasInfix "10.0.0.3:8080" lb-prod.services.haproxy.config;
    expected = true;
  };
```
Groups seen: kernel (run, st), nixos (test-basic; fleet-demo.*), readme (test-hello-world, test-effect-rotation, test-nested-cycles).
Module args: kernel/run-tests.nix:2-4 takes `{ lib, ned, ... }`; fleet-demo/default.nix:1-3 `{ config, lib, ... }` with `config._module.args.fleet-demo = config.fleet-demo;`.

## TEMPLATE TESTING
templates/ci/flake.nix:1-8 (verbatim):
```
{
  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    with-inputs.url = "github:denful/with-inputs";
    with-inputs.flake = false;

    ned.url = "github:denful/ned";
```
templates/ci/with-inputs.nix:1-9 (verbatim):
```
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  locked = lock.nodes.with-inputs.locked;
  with-inputs = builtins.fetchTarball {
    url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.zip";
    sha256 = locked.narHash;
  };
in
(import with-inputs).from.flake ./.
```
templates/ci/ned.nix:1 (verbatim):
```
(import ./with-inputs.nix { ned.outPath = ../..; }).ned.lib { }
```
Dependency: tests.nix:1 passes `ned.outPath = ../..` → lib under test = local repo root (path, not github). Template flake.nix's `ned.url = "github:denful/ned"` is NOT used by `just test` (tests.nix path bypasses flake inputs for ned). `with-inputs` pulled from flake.lock rev/narHash via fetchTarball. `nix-unit --expr` (Justfile:15) evaluates tests.nix directly; no `--flake` in Justfile/test.yml.

## GEN INPUT
MISSING: no `gen` / `sini/gen` reference found in /home/vic/hk/ned (rg -n -i '\bgen\b' --glob '*.nix' → 0 hits; rg 'sini/gen|gen\.' flake.nix → 0 hits). Template flake.nix inputs (verbatim, full block):
```
  inputs = {
    with-inputs.url = "github:denful/with-inputs";
    with-inputs.flake = false;

    ned.url = "github:denful/ned";

    import-tree.url = "github:denful/import-tree";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-effects.url = "github:denful/nix-effects/push-pyplsuktytks";
    nix-effects.flake = false;

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-maid.url = "github:viperML/nix-maid";
  };
```
Not verified: `nix-unit --flake` attempts recorded in /home/vic/hk/ned/vic/conv.md:85-213 and vic/state.md:8 (not read; out of time budget).

## OPEN
- gen input: not present in ned; check other repos. status: open.
- nix-unit --flake invocation path: conv.md notes attempts; outcome unread. status: open.

## DEAD
none verified.
