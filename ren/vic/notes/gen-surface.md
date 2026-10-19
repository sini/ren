# gen surface: downstream consumption of /home/vic/hk/gen/gen (github:sini/gen)

MISSING: /home/vic/hk/gen/gen/Justfile (no Justfile in any gen dir)
MISSING: /home/vic/hk/gen/gen/kernel.nix
MISSING: /home/vic/hk/gen/gen/templates (and no templates/ anywhere under /home/vic/hk/gen)
NOTE: gen-* libs are SIBLING dirs /home/vic/hk/gen/gen-*, not nested under gen/gen.
NOTE: gen-harness README + mkCi.nix found at /home/vic/hk/gen/gen-harness/.

## FLAKE OUTPUTS (verbatim /home/vic/hk/gen/gen/flake.nix:143-307)
```nix
  outputs =
    inputs:
    let
      # ★★★ L3 APPLIED TO THE HUB — the flake output IS the root, applied to what this flake's own
      # inputs supply (owner-ruled 2026-09-14: "`mkGenLibs` stops being a fixed point and becomes a
      # CONSUMER of the same pattern every member follows"). There is ONE construction of the roster
      # and `./default.nix` is it; the two entry paths differ only in WHO supplies the members. Here
      # the flake supplies them, so `follows` governs every one; the standalone path falls back to
      # the root `flake.lock`. Before this, `./default.nix` did not exist and the hub was flake-only.
      #
      # ★★ THE THREE UNAPPLIED `.lib`s ARE L3's SECOND ARM ARRIVING, NOT AN EXCEPTION LIST.
      # gen-program, gen-delivery and gen-assemble publish `lib = import ./.` UNAPPLIED, although
      # each declares gen inputs (followed above): the substrate they need is the consumer's to
      # supply, not their own flake's; the other 18 publish an applied set. What is written here is therefore the member's own L3 arm read off its published
      # surface, and it is LOUD if that arm ever changes — applying an already-applied set is
      # `attempt to call something which is not a function but a set`, and a member that went the
      # other way arrives as a function and reds `ci/mkgenlibs-eval.nix`'s deepSeq force (den-hoag-ydm94
      # R7 retired the root's own forcing output, `roster`, once that check was confirmed to force the
      # same key set more deeply). The rejected
      # alternative was to arity-dispatch here (`if builtins.isFunction v then v { } else v`), which
      # makes the hub TOLERANT of either shape and so accepts a member that landed the wrong arm in
      # silence — the failure L3 exists to make loud.
      #
      # AN UNAPPLIED ARM IS PRECISELY THE ONE WHOSE ARGUMENTS THE CONSUMER OWES (ADR-0008 §1).
      # Until this fold, the three were applied to `{ }`, so each self-fetched its own substrate
      # instance out of its own `ci/flake.lock` instead of receiving the hub's — the defect
      # `./lib/hubSubstrate.nix` closes. That file is a pure function of `members` below (never of
      # `inputs`), naming exactly the substrate each of the three needs; the `mapAttrs` fold applies
      # every member's `.lib` — applied set or unapplied function alike — at this ONE site, so there
      # is nowhere else in this file a mis-keyed application could be written.
      members = {
        algebra = inputs.gen-algebra.lib;
        aspects = inputs.gen-aspects.lib;
        bind = inputs.gen-bind.lib;
        class = inputs.gen-class.lib;
        dispatch = inputs.gen-dispatch.lib;
        graph = inputs.gen-graph.lib;
        identity = inputs.gen-identity.lib;
        link = inputs.gen-link.lib;
        memo = inputs.gen-memo.lib;
        merge = inputs.gen-merge.lib;
        prelude = inputs.gen-prelude.lib;
        product = inputs.gen-product.lib;
        schema = inputs.gen-schema.lib;
        scope = inputs.gen-scope.lib;
        select = inputs.gen-select.lib;
        settings = inputs.gen-settings.lib;
        types = inputs.gen-types.lib;
        view = inputs.gen-view.lib;
      };

      # THE FOLD IS SELF-REFERENTIAL: `hubSubstrate.nix` reads `members // applied`, so an unapplied
      # member (gen-inspect) can take another unapplied member (gen-program) APPLIED, and each is
      # applied exactly once. `mapAttrs` needs only the file's key set, which its attrset literal
      # supplies without forcing `members // applied`. See that file for the cycle hazard.
      applied = builtins.mapAttrs (k: args: inputs."gen-${k}".lib args) (
        import ./lib/hubSubstrate.nix (members // applied)
      );

      roster = import ./. (members // applied);

      # The PUBLISHED two-stage surface, kept exactly as its consumers call it. Stage 2's argument
      # was always vestigial — every caller passes `{ }`, `{ inherit lib; }` or `{ lib = null; }` and
      # the roster ignores it — so the compat wrapper belongs here, at the publication site, while
      # `lib/mkGenLibs.nix` is the construction and returns the roster itself. That is what lets
      # `import <gen> { }` yield the roster directly while `gen.lib.mkGenLibs { … }` still answers
      # for its thirteen call sites across this hub and gen-demo.
      mkGenLibs = _: roster;

      # A stratum bucket is a SELECTION from the flat roster, never a re-import: `substrate.prelude`
      # and the flat `prelude` are one value rather than two evaluations of the same source. That
      # distinction is invisible to a names-and-types comparison — a library re-imported at a
      # different pin has identical names and identical types while being a different build — so it
      # is the roster, not a reconstruction of it, that the buckets are cut from.
      bucket =
        s:
        builtins.listToAttrs (
          map (n: {
            name = n;
            value = roster.${n};
          }) (builtins.filter (n: roster.strata.${n} == s) (builtins.attrNames roster.strata))
        );
    in
    {
      # `lib.mkCi` is NOT here, and its absence is the point rather than an omission: the CI
      # wrapper is `gen-harness.lib.mkCi`, in its own repository. A library's test harness must
      # not depend on the aggregator that pins that library, and re-exporting it from here was
      # the last edge that made it.
      lib.mkGenLibs = mkGenLibs;

      # The successor compose (ADR-0031 F2's "compose S2 core → S2" row), bound against the
      # roster: gen-merge as the engine, gen-memo's two decision functions as the plane. The
      # construct itself (lib/compose.nix) binds no constructor vocabulary and takes `specialArgs`
      # caller-total; a bare caller performs its own constructor threading, and the flakeModule
      # below performs it for hub-fronted trees.
      #
      # INTERIM EXPOSURE. The construct is the settled S2 core, but this hub surface does NOT
      # satisfy ADR-0027 — it is the same interim standing as `flakeModules.default` below, and
      # the true framework surface that arrives with den v2 / quiver is what re-homes the
      # exposure. Do not build a framework contract on top of the exposure's location.
      lib.compose =
        (import ./lib/compose.nix {
          engine = roster.merge;
          inherit (roster.memo) warmAdmits warmTrace;
        }).compose;

      # The stack layers, each selected by the roster's own stratum declaration. The `retiring`
      # declaration publishes no path here by design: inviting a consumer to select a library on its
      # way off the roster is the adoption that value exists to prevent, and its members stay
      # reachable through `mkGenLibs`.
      #
      # `framework` DOES publish, and the asymmetry with `retiring` is the point rather than an
      # inconsistency. The two were once excluded by one sentence whose stated ground — a consumer
      # selecting a leaving library — is true of `retiring` alone; a framework library is not
      # leaving. What forced the reading is that a framework TOOLKIT is a library every assembling
      # framework is meant to reach, so withholding its path made the intended consumption path the
      # one case the hub does not serve.
      lib.substrate = bucket "substrate";
      lib.modules = bucket "modules";
      lib.aspects = bucket "aspects";
      lib.framework = bucket "framework";

      flakeModules.genLibs = ./flakeModules/genLibs.nix;

      # The flake-parts entry surface, rehomed from gen-flake under ADR-0031 F1 — the hub is the
      # single input a consumer takes, so the ergonomics module belongs beside the roster it binds
      # against. `default` is flake-parts' own convention and the name the source exported under, so
      # a consumer's `imports = [ inputs.gen.flakeModules.default ]` reads unchanged.
      #
      # INTERIM. It does NOT satisfy ADR-0027; the true framework surface arrives with den v2 /
      # quiver bound against that interface, and this module is what that replaces. The file header
      # carries the marker and names the two measured defects that travelled with it unfixed
      # (den-hoag-es9g).
      flakeModules.default = ./flakeModules/default.nix;

      # The flake-parts `evaluate` for gen-bind's outputs terminal (den-hoag-52hn7; ADR-0031 F1 and
      # ADR-0027, re-affirmed 2026-09-28): gen-bind publishes `crossing.mkOutputsTerminal evaluate` in
      # substrate vocabulary, and this is its one flake-parts binding — a CALLER of that construct,
      # never a relocation of it. The consumer supplies flake-parts' own `evalFlakeModule`: this hub
      # declares no flake-parts input because it evaluates none.
      #
      # INTERIM, the same standing as `flakeModules.default` above: it does NOT satisfy ADR-0027 and
      # leaves with that surface when the den v2 framework surface arrives (den-hoag-es9g, which
      # carries `flakeModules.default`'s INTERIM marker).
      lib.flakePartsEvaluate =
        {
          evalFlakeModule,
          inputs,
          self,
          systems ? [ ],
        }:
        body:
        (evalFlakeModule
          {
            inputs = inputs // {
              inherit self;
            };
          }
          {
            imports = body;
            inherit systems;
          }
        ).config.flake;
    };
}
```

## HOW TO GET LIBS
- flake consumer: `gen.lib.mkGenLibs` = /home/vic/hk/gen/gen/flake.nix:231 (`lib.mkGenLibs = mkGenLibs;`)
- roster def: /home/vic/hk/gen/gen/flake.nix:210 (`mkGenLibs = _: roster;`), roster at :202 (`roster = import ./. (members // applied);`)
- other lib outputs: `lib.compose` :243; `lib.substrate|modules|aspects|framework` = buckets of roster (flake.nix ~260-263); `lib.flakePartsEvaluate` :287
- flakeModules: `flakeModules.genLibs` (flake.nix ~265), `flakeModules.default` (flake.nix ~276)
- standalone: `import <gen> { }` yields roster directly (flake.nix comment, default.nix top; roster called at default.nix:157 via `builtins.seq forced (wire {...})`)
- sibling input pattern (gen-delivery README): `genDelivery = inputs.gen-delivery.lib { algebra = inputs.gen-algebra.lib; aspects = inputs.gen-aspects.lib; prelude = inputs.gen-prelude.lib; };`
- gen-assemble/gen-delivery/gen-program publish `lib = import ./.` unapplied (flake.nix comment, outputs block)

## LIB ROSTER (13 requested; purpose from README line 1-30)
- gen-aspects: aspect type system (traits, classification, dispatch). README:1. Deps gen-identity/merge/prelude/schema.
- gen-class: class-share mechanism (partition/contract/apply/gate). README:1. Layering gen-prelude→gen-class.
- gen-merge: byte-mode module merge engine, exports `evalModuleTree`. README:1. Layer gen-prelude→gen-types→gen-merge.
- gen-types: structural type checker, `verify: v → null|err`. README:1.
- gen-scope: HOAG/RAG scope-graph evaluator, well-founded engine, staged minting, demand cascade; exports `eval`, `evalDebug`. README:1.
- gen-graph: accessor-based graph query combinators. README:1.
- gen-assemble: shared framework toolkit, `import ./lib` takes {prelude,scope,algebra}, nine exports. README:1.
- gen-delivery: delivery-class realization, `project`, `realize`. README:1-30 example.
- gen-harness: CI harness, exports `lib.mkCi` only. README:1.
- gen-schema: typed record registry. README:1.
- gen-program: logic-program consumer of gen-scope; exports `program`, `model`. README:1-30 example.
- gen-rules: closure defunctionalization; exports `defunctionalize`, option `lambdas`, `mkApply`. README:1-30.
- gen-link: cross-flake aspect federation (`link` conductor). README:1.
- NOTE: export fn line:cites not verified for each lib (time limit). Only names quoted from README text above.

## HARNESS/CI
gen-harness README usage (/home/vic/hk/gen/gen-harness/README.md:25-60) verbatim:
```nix
```
gen-harness mkCi args (/home/vic/hk/gen/gen-harness/mkCi.nix:14-60): `{ inputs, name, testModules, readRoots ? [ ], specialArgs ? { }, extraModules ? [ ] }`
Suites run: `nix develop ./ci --command ci` (gen-harness README:~50).
Gen hub self-test cmd: none in Justfile (MISSING). Hub ci dir: /home/vic/hk/gen/gen/ci (flake.nix referenced). Test-file names (ci/): mkgenlibs-eval.nix, pin-coherence.nix, sole-evaluator.nix, etc.
gen-harness ci/: agents-md-sheet-arms.nix, process-plane-guard.nix, read-roots-guard.nix, repl.nix, tests-error.nix, tests-process.nix, flake.nix.

## TEMPLATES
MISSING: no templates/ dir at /home/vic/hk/gen/gen or /home/vic/hk/gen.
