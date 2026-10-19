# DEFER + GEN CANDIDATES (CVMN). gen untouched until vic OKs each.

## DEFERRED in ren v1 (not implemented, reason)
- ~~D1~~ DONE (nix/lib/strata.nix) stratum-3 per-branch static check (fleet-ren C5, strata row 3): reads of `outputs` stay lazy; a branch reading outputs it forwards into gives nix infinite recursion, not a named error. needs collector-graph edges known b4 eval (which outputs a branch reads = not static in Nix). candidate: declare reads (`into.reads = [...]`) or gen-graph order over declared edges.
- ~~D2~~ DONE (identity.nix, gen.schema identityHashForKind) `same` via gen-schema id_hash (A7, fleet-ren.md:102): v1 compares Ren `__id` = "<is-root kind>:<name>". unproven gen path; needs gen-schema minted kinds.
- ~~D3~~ DONE (F2 guard enforced) kind fn-form guard (`replica = { db, region }: when P { }`): stored as `__guard`, NOT enforced (instance violating P accepted).
- ~~D4~~ DONE (scopes.nix on gen.scope mkKinds/eval + parseParent; glue only where gen refuses: cyclic below, once-per-path, sibling order — measured) scope tree via gen.scope.mkKinds/eval: R2 is glue (proven possible on toy input by lawyer; ids `bare@parent` must be minted by Ren). swap when parity test exists.
- ~~D5~~ DONE (pipeline-args.nix) renArgs leak internal keys (`__scope instance kinds kind`) into content fns.
- ~~D6~~ DONE (class w/o at = every scope) class with `at = null` unhandled.
- D7 LAW-FAITHFUL (fleet-ren.md:100 forwarding rule is stated for classes only; channels w/ into = data collectors L24,L307). Forward from channel into = design extension, VIC Q. channel `into` may return only top-level outputs + own channel name (R8/R9 rulings, fleet-ren 89, 306-307).

## GEN CANDIDATES (sound? verified?)
- G-a gen-scope README:198-215 calls `mkKind { } "name"` (2 args); code cascade.nix:363 takes 1 attrset w/ `name`. DOC BUG, verified by supervisor read. safe.
- G-b gen-scope folds lacks dedup `set` + recursive `mergeAttrs` w/ equal-leaf merge (folds.nix:426; mergeAttrs shallow, refuses shared sub-key — measured by R5 agent). Ren glue in nix/lib/folds.nix. candidate `mergeAttrsDeep`.
- G-c gen-aspects README:39 lists meta.drop/meta.substitute; 0 impl hits. Ren `excludes` = glue in activation.nix. candidate: exclude in gen-aspects.
- G-d forwarding (fleet-ren GAP): gen-delivery `extraModules` = inlet only. Ren glue = lazy forward fixpoint in classes.nix.
- D8 positive aspect cycles = named error in v1 (law L111 bans only negative). stricter than law; awaiting vic.
