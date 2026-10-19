# gate-plan-1: plan.md CONTRACTS (L22-37) vs fleet.md v30
Verdict: REJECT. Construction findings: 7. Policy findings: 6. Accepted lines: 6.
Prior-art sweep: not done (8-min cap). No br/quipu read.
Read: plan.md L22-46, fleet.md L81-463, gen bcbc5ca -> gen-select /nix/store/0fhlj9ip8kkmyjzss67j6kdiqa0cbwc9-source/lib/{match,constructors}.nix.
Probe (both arms): `builtins.functionArgs ({...}: 1)` => {} and `builtins.functionArgs (x: 1)` => {}. builtins.toXML tells them apart (attrspat vs varpat).

## construction (block)
L35 pools attrs "same leaf twice = error" | REJECT | fleet.md:453 "two features giving `agenix` different urls evaluating" (must not) + L454 "`agenix = { url; inputs.nixpkgs.follows; }` from two features that agree on `url`" (must appear) + L96 "attrs (recursive, conflict = error)" | secrets (L327-329) emits agenix.url from 5 host scopes into the same flake-inputs pool, so the contract errors and L453 cannot be produced. Fix: an error only for the same leaf with UNEQUAL values; equal leaves merge. Treat derivations and `_type` values as leaves.
L25 field value "deep check ... else type.check" | REJECT | fleet.md:124 `settingsT = t.submodule { options.kernel.channel = maybe ... }` + L363 `host.settings.kernel.channel` | The contract only checks the value. lb/stage set no settings, so `settings = {}` and `{}.kernel` throws in kernel (L360-366) on every host. Fix: compute each field value through the type's merge (`lib.mergeDefinitions` / `type.merge`), so submodule defaults fill in; check alone is not enough.
L23/L24 kind rec `is` | REJECT | fleet.md:87 "`is = K` ... has K's fields. `below` and `spawns` are **not** inherited" | The contract states neither rule. guest->host->machine must inherit fields transitively (ci needs environment/channel/system/addr plus `on`). Fix: add "fields = own // fields(is) transitive; below/spawns never inherited".
L28 children "spawns.K or (all inst of K)" | REJECT | fleet.md:85 "A `spawns` key outside `below` is an error" + L458 "a `spawns.user` on a kind whose `below` lacks `user` evaluating" | Rule absent. A stray spawns key is silently ignored. Fix: add the error. Also define "all inst of K" = `ren.K` only, not subkind instances. If `ren.host` includes ci, then inEnv (L215) spawns ci under staging and under stage, and L438 breaks.
L29 "compile -> gen-select selector; `within` = ancestor-or-self" | REJECT | gen-select match.nix:122-123 `tag == "within" ... (ctx.ancestors id)` and TERMINOLOGY.md:270 "within: Any ancestor matches" (strict) | The line contradicts itself: a straight compile to gen-select within gives strict ancestors. fleet.md never needs self-match (L169-183, L342, L346 all pair `user` with `within <non-user>`). Fix: pick strict, which matches gen. Otherwise compile to `anyOf [P (within P)]` and say so.
L34 content "fn w/ formals" vs "fn w/o formals" | REJECT | fleet.md:338 `overlays = { ... }: final: prev: ...` (must work) vs L450 "a bare `final: prev:` emission evaluating as content" (must not) | The obvious test `functionArgs f == {}` cannot tell them apart. Measured: both give {}. An implementer using it rejects L338/L345/L405/L407/L329. Fix: name the discriminator in the contract (builtins.toXML attrspat vs varpat, or the lib equivalent).
L26 `__id="<rootKind>:<name>"`; L30 `same a b: a.__id == b.__id` | REJECT | fleet.md:102 "`same a b`: identity (gen-schema `id_hash`)" | This bypasses the published gen surface fleet names. Fix: back `same` with gen-schema id_hash, or get a ruling that __id equals it.

## policy (non-blocking)
L32 activation `(at ∧ ¬excluded) ∨ included` | ACCEPT-cond | fleet.md:98 "`includes` and `excludes` work in the aspect's scopes and their subtrees" | Because of the brackets, an included aspect can never be excluded. No row tests this. Fix: state the intent explicitly. Note: subtree inclusion makes nginx active at ci (child of stage). No row forbids it, but ci gets nginx, meta "web" and persist /var/lib/nginx (to ci, not stage, so L447 holds).
L36 forward "nearest ancestor-or-self s' w/ K-branch, (K,s')≠(C,s)" | ACCEPT-cond | fleet.md:438 "bob's HM in ci -> ci's nixos -> stage's `microvm.vms.ci.config`" | Derived: produces L437/L438 (ci guest branch -> skip (nixos,ci) -> stage) and homeDarwin in place (L182). Unstated: what happens when no s' exists. Fix: name the error.
L35 `one` = exactly 1 else error | ACCEPT-cond | fleet.md:435 | Produces L435. The `deployment` pool is empty at ci/studio, so the error must fire only when forced (lazy renArgs). Fix: state laziness.
L35 list = scope-path order | ACCEPT-cond | fleet.md:436 | web-1 before web-2 holds. A lexicographic id string would put web-10 before web-2. Fix: define as tree order or name-sorted per level.
L37 outputs "recursive merge ... leaf conflict" | ACCEPT-cond | fleet.md:449,454 | Define a leaf: derivation / nixosSystem / non-plain attrs. Otherwise two nixosConfigurations.lb recurse into system internals.
L34 renArgs `{lib parent}` override margs | ACCEPT-cond | fleet.md:386 `homeManager = { devices, parent, lib, ... }:` | Ren's lib shadows HM's `lib.hm` in class content. Fix: margs.lib wins for class keys.
L24 fn kind form guard | ACCEPT-cond | fleet.md:249 `replica = { db, region }: when (...) { }` | Unstated: what the guard sees (instance fields?) and what failure does (error vs drop).

## accepted
L27 bindings nearest-wins + field-name | ACCEPT | fleet.md:249,401 `scrape = { db, region, replica, ... }` | Produces replica bindings. host=ci at ci (L437). The home field `user` is shadowed by the user self-scope.
L30 `is P x` | ACCEPT | fleet.md:105,461 | parent=stage scope matches desktop. ci does not (L461).
L31 aspect rec | ACCEPT | fleet.md:97-100 | -
L33 landing errors | ACCEPT | fleet.md:99-100,350-351 `tiling ... homeDarwin` | homeDarwin lands at alice/bob@studio, so it is not "in none". Non-mac users skip silently. L451 holds.
L36 classes ≤1 branch, into keys | ACCEPT | fleet.md:90-92,145-146 | colmena/age-manifest go out as channel emissions at metal hosts. L463 holds.
Rows L439-L447, L452, L455, L461 | ACCEPT (derived by hand, not evaluated) | - | -
