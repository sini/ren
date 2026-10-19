# gate-final-1 — Ren implementation vs fleet-ren.md (ren-v30.1) + plan.md

Verdict: **REJECT** — 6 construction, 4 policy. Suite re-run: `just test` exit 0, `112/112 successful` (evaluated).
Prior-art sweep: plan.md AMENDMENTS A1-A8 + GEN-FIT read; no tracker sweep done (time limit).
Evaluated: test run, greps. Derived (code reading, not probed): every "never read"/"not wired" claim below; the grep that showed it had a positive control that matched (`guard` matches kinds.nix:54 and kinds-check.nix:55; `isAt` matches predicates.nix:48 and the test file).

## Findings (area | verdict | evidence | fix)

1. kinds below/spawns direction | ACCEPT | kinds.nix:50-51, scopes.nix:161-177; test scopes.nix (test-kinds-is), rows-c test-no-guest-in-guest | —
2. spawns key outside below = error | REJECT (construction) | scopes.nix:166-169 checks only inside `childrenOf`, so only for a kind that has a scope. A kind with no scopes and a bad `spawns` key gets no error. Law L94 has no such exception; gen mkKind refuses at registration | move the check into mkKinds (kinds.nix:51); add a test where the kind has zero instances
3. is = K (fields inherited, below/spawns not) | ACCEPT | kinds.nix:50-53; tests kinds.nix test-fn-form/is, scopes test-kinds-is | —
4. instance once per path | ACCEPT | scopes.nix:199-200; test scopes.test-twice-on-path | —
5. fn-form kind guard `when P {}` (replica, law L257) | REJECT (construction) | guard is stored (kinds.nix:54, kinds-check.nix:55 `__guard`) and nothing reads it. grep `guard` over nix/lib + templates: no consumer. A replica with db.zone != region.zone is accepted silently. The test at ci/modules/lib/kinds.nix:149-160 asserts only that the guard equals "P", so it checks the name and not the behaviour | enforce the guard in mkInstances (throw if the guard is false), or state a `# ruling:` that it is unenforced; add a red test with mismatched zones
6. classes: branches disjoint | ACCEPT | pipeline.nix:55-65 (>1 match throws); test classes.nix | —
7. classes into: class key forwards, channel key emits, other = output | ACCEPT | classes.nix:47-81; rows-a test-chained-forward, rows-b test-meta-emission | —
8. channels fold/at/to | ACCEPT with note | folds.nix:26-30, pipeline-out.nix:38,61; folds tests, rows-a fold tests | note: channel `at` is checked only for aspect emissions (pipeline-out.nix:38). `into` emissions from class collectors (pipeline-out.nix:58) bypass it. That is policy: law L102 does not say what happens to an `into` emission outside `at`
9. fold list order "by scope path" | ACCEPT | folds.nix:5 is a string sort on ids `kind:name/...`. Note: this is not gen's `bare@parent` (C1) | —
10. aspects at / no-at fires only when included | ACCEPT | activation.nix:72-74; activation tests | —
11. includes/excludes in subtree; exclusion beats inclusion (A8) | ACCEPT | activation.nix:68-74 | —
12. aspect key neither class nor channel = error | REJECT (construction) | content.nix:48 runs only through `landed`. The ruling at pipeline-out.nix:19-26 returns `{}` for an aspect that is active nowhere, so an aspect with no `at`, or one that never fires, can carry key `nope` and get no error. Law L107 ("any other key is an error") does not depend on landing. The ruling covers L108 only and silently widens to L107 | check keyKind for every aspect regardless of activity; add a test with an inactive aspect carrying `nope`
13. landing: key lands in none of its scopes = error | ACCEPT | content.nix:50-51; mkflake.nix:131 area | —
14. predicates and/anyOf/not/within/has/when | ACCEPT | predicates.nix:9-43 (gen.select); tests predicates.nix (test-within-strict = A5, test-when, test-aspect) | —
15. aspect refs stratified; negative cycle is an error | REJECT (construction) | activation.nix:61-66 also throws on a POSITIVE cycle ("aspect cycle"). Line 1 admits it. Law L111 makes only negative cycles errors, so a valid program (a includes b, b includes a) is refused. There is no `# ruling:` for this | mark it as a `# ruling:` and get vic's sign-off, or allow positive cycles
16. `same a b` | ACCEPT | predicates.nix:82 (A7 __id); used by mkflake.nix:47,69 and fleet kinds.nix:72 | —
17. `is P x`, x an instance (law L112: nearest ancestor-or-self scope on the current path, error if none) | REJECT (construction) | `predicates.isAt` (predicates.nix:48-57) is called only by unit tests (ci/modules/lib/predicates.nix:133-139). Bindings like `host`/`user` are instances (scopes.nix:188). load.nix:34 sends a non-scope x to `renLib.is`, which returns the inert record `{__ren="is"}` (predicates.nix:76-80). So `is P host` in content yields an attrset, not a bool, and never throws on a missing scope. Only the `parent` (scope) case works, which the ruling at load.nix:32 covers | in load.nix:34 route the instance case to `P.isAt ctx` at the current scope id; add a fleet-level test (`is P host` true, false, and the error case)
18. Rulings vs law: ruling citations are stale | REJECT (construction, cheap) | pipeline-out.nix:19 cites :101,104 (actual :108,107). :63 cites :89, which is the heading. load.nix:6 cites :95, which is `is = K`; the rule is around L93. All are offset by the +7 shift | re-cite against the current fleet-ren.md
19. ruling: channel into = top-level outputs only (pipeline-out.nix:63-74) | ACCEPT | the law says nothing on keys of a channel `into`. Class `into` keys are covered by L26/L100. This settles an open point but is marked as a ruling | —
20. ruling: `ren.<kind>` exists for every kind (load.nix:6) | ACCEPT | consistent with "instances: ren.<kind>.<name>" | fix the citation (see 18)
21. ruling: file shape (load.nix:2) | ACCEPT | matches fleet-ren.md mkFlake form | —
22. tests: names-only | REJECT (policy) | ci/modules/lib/kinds.nix:149-160 (guard == "P"); rows-a/rows-c tests named "*-into-conflict" assert `errs ... == true`, so they depend on the `errs` helper, which was not inspected; smoke.nix:20,24 check only `? studio` / `? alice-laptop` (presence, legitimate as smoke) | replace the guard test with a behavioural one (see 5)
23. tests: stubs faking results | ACCEPT | fleet-stubs.nix is evalModules over freeform options. Ren routing is real, and the stub only stands in for nixpkgs modules (stated at :1-2). Tests check routed values (rows-a :36-86), not stub constants | —
24. lib domain-freeness | ACCEPT | grep -w host|user|nixos|darwin|home|guest|environment|packages|colmena|system|machine over nix/lib: hits only in comments (load.nix:1-3 "fleet"; pipeline-out.nix:68 `packages` example). Positive control: same grep on templates/fleet/kinds.nix = 6 lines for `host` | optional: drop `packages`/`fleet` from the lib comments
25. gen: select.matches | ACCEPT | predicates.nix:46 `s.matches` | —
26. gen: scope.folds | ACCEPT | folds.nix:26,29 (list, one via gen); attrs glue reasoned at folds.nix:13 | policy: `set` (folds.nix:27) has no `# glue:` line (plan.md:56 says glue); add one
27. gen: graph.topoOrder | ACCEPT | activation.nix:54 | —
28. gen: scope.mkKinds/eval (GEN-FIT USE, plan.md:54) | ACCEPT-with-note (policy) | scopes.nix:1 `# glue:` gives "no time to prove node-set parity". A reason exists but it is about schedule, not technical. Side effect: ids are `kind:name/...`, not C1's `bare@parent` | track it as debt
29. gen: kind tests via `when` instead of gen kind | ACCEPT | plan.md:55 allows it; predicates.nix:26 | —

Counts: ACCEPT 21 (2 of them carry policy notes, 26 and 28). Construction REJECT 6: 2, 5, 12, 15, 17, 18. Policy REJECT 1: 22. Policy notes 3: 8, 26, 28.
Not checked: the body of the `errs` helper in rows-c; flake.nix template; whether test-hm-platforms-not-linux (rows-b:123) is vacuous over an empty user list; tracker prior art.
