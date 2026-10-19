# gen API facts (CVMN). VERIFIED = supervisor ran cmd 2026-10-19. RELAYED = reader report, not re-checked.

## entry
- VERIFIED hub = ~/hk/gen/gen. default.nix = L1 shim: named formal per member, `inputs` bag, `src`/`dep` resolver formals, default reads ./flake.lock (fetch). gen/flake.nix:210 `mkGenLibs = _: roster;` :231 `lib.mkGenLibs`.
- RELAYED gen-aspects non-flake: `import gen-aspects { inherit lib; }` (needs nixpkgs lib) README:68-126.

## gen-scope
- VERIFIED lib/cascade.nix:363 `mkKind = { name, below ? [], resolve ? null, spawns ? {}, nta ? {}, dedupKey ? null, fold ? null, kindValue ? null }:` returns DECLARATION; `mkKinds [ decls ]` = ordered left fold, sole kind producer; below names resolved vs earlier kinds ⟹ cycle inexpressible.
- VERIFIED README:198-215 uses `mkKind { } "admin-user"` 2-arg form ≠ code 1-arg. GEN DOC BUG (defer list).
- VERIFIED spawns.<produced> = self: id: { "<bareId>@${id}" = { decls = ..; }; }; spawn handle serves `self.node id` = { id parent decls type } only (no evaluated attrs). produced kind must ∈ below.
- VERIFIED build-nodes.nix:335 child id = "${bareId}@${parent}" (NOT parent/child as fleet.md L474 says).
- RELAYED build-nodes out: { nodes.<id> = { id type parent decls }; nodeOrder = [..]; }. reserved labels P I imports parent.
- RELAYED exports (lib/default.nix): algebraicGraph buildRoots queries resolve calculus structural interface eval program leastModel wellFounded acceptance engine stratify ascent mint folds cascade foldEquations.
- RELAYED engine.eval {} { children marks <attr> = self: id: ..; } roots; result.get id attr. engine.inherit' for parent-chain inherit.

## gen-aspects
- RELAYED exports: aspectsType aspectSubmodule instanceOf instancesFor keyCategory pred guard applyGuard includeSitesOfEntry ... (default.nix L79-157).
- RELAYED keySemantics.<key>.category = "class" (deferredModule) | "channel" (raw); undeclared keys = nested aspects.
- RELAYED meta.drop/meta.substitute in README:39 but 0 impl hits ⟹ excludes GAP confirmed (fleet.md L486).
- RELAYED pred vocab guard.nix: eq has all any always not (2nd predicate vocab vs gen-select).
