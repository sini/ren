# Ren plan (CVMN). Oracle = ~/hk/ren-and-stimpy/vic/fleet.md v30 (READONLY). Supervisor-owned design.

## LAWS
- ren = flake, ONLY input github:sini/gen pinned rev bcbc5ca579614643fa3433034fd0248b0d551f65 (= fleet.md:469). Non-flake: `import <gen outPath> {}` = roster {algebra aspects ... select scope schema ...} (probe vic/probes/gen-entry-upstream.nix).
- local ~/hk/gen STALE (gen-select no anyOf). never edit gen until DEFER list written + soundness shown.
- lib = NO domain words (no host/user/nixos...). domain lives ONLY in templates/fleet.
- tests: nix-unit like ~/hk/ned: `just test` = `nix-unit --expr 'import ./templates/ci/tests.nix'`; lib tests in templates/ci/modules/lib/*.nix, template tests in templates/ci/modules/fleet/*.nix. leaf = `test-<name> = { expr; expected; }` (+ expectedError for refusals). each test <1s.
- template CI uses STUB inputs (nixpkgs lib real; nixosSystem/darwinSystem/homeManagerConfiguration/... = lib.evalModules w/ stub option modules) ⟹ fast, real merge semantics.
- every nix file <100 lines. no nested let. no `with`. private lets.

## LIB LAYOUT (nix/lib/*.nix, each ≤100 lines)
- default.nix `{ gen }: { load mkFlake and anyOf not when within has is same fold }`
- kinds.nix: parse kind decl → kind record; kind ref doubles as option type; subkind closure; instance validation + defaults.
- scopes.nix: stratum 0 tree; bindings.
- predicates.nix: compile Ren preds → gen-select selectors; `is`, `same`.
- activation.nix: stratum 1 aspects at/includes/excludes, stratified.
- content.nix: stratum 2 landing, content-fn call, emissions, pools.
- folds.nix: list set attrs one.
- classes.nix: stratum 3 into, forwarding, channel-into, outputs merge.
- load.nix: fixpoint `load = file: args:` gives user `ren` = lib // processed decl.

## CONTRACTS (internal shapes; agents MUST use these)
- kind rec: `{ __ren="kind"; name; below=[name]; spawns={name=s: {n=inst}}; is=name|null; fields={f=type|option}; guard=null|pred; check; name; description; merge; }` (option-type iface: kind ref usable in t.listOf).
- decl kind forms: attrset (reserved keys below spawns is; rest fields) | fn `{ a, b }: when P { }` (fields = arg names typed as kinds of same name; guard P).
- field value: `type` = required; `lib.mkOption{type;default}` (`_type="option"`) = default. deep check: listOf/nullOr via nestedTypes.elemType, kind ref via __ren, else type.check.
- instance: `{ __ren="instance"; kind; name; __id="<rootKind>:<name>"; <fields> }`. names unique per `is`-root family (host.ci + guest.ci = error).
- scope value: bindings // `{ __ren="scope"; __scope=id; name; parent=scope|null; }`. id = path string "k:n/k:n". bindings: nearest wins: self kind name + all `is` ancestors → self inst; self inst's instance-valued fields by field name; then parent bindings.
- roots: kinds w/ `below` that no `below` lists; children: for K in below: `spawns.K or (all inst of K)` applied to parent scope. instance ≤1 per path.
- predicate value: kind rec | instance | scope | aspect rec | `{__ren="pred"; op; args}` (and anyOf not when within has). compile → gen-select selector over ctx {data parent children ancestors siblings}; `within` = ancestor-or-self.
- `when f`: f bindings → bool. `is P x`: x's nearest ancestor-or-self scope on current path matches P; error if none. `same a b`: a.__id == b.__id.
- aspect rec: `{ __ren="aspect"; name; at=pred|null; includes=[aspect]; excludes=[aspect]; keys={k=v}; }`.
- activation: active(A,s) = (at matches s ∧ ¬excluded) ∨ included by active B at s-or-ancestor (B's scopes+subtrees); excluded(A,s) = some active B at s-or-ancestor excludes A. aspect-ref in pred = active here. stratify by polarity; negative cycle = named error.
- landing: key k of active A at s lands iff (k class ∧ some branch.at matches s) ∨ (k channel ∧ (chan.at or any) matches s). key neither class nor channel = error. key landing in none of A's scopes = error.
- content value: non-fn = as is; fn w/ formals = called w/ Ren args (bindings // pools // {lib parent}); for class keys wrap as module: `setFunctionArgs (margs: f (margs // renArgs)) (formals − renArgs names)`; fn w/o formals (`final: prev:`) as emission = error "wrap in { ... }:".
- pools: channel c emission at e → receivers = scopes matching (to e); pool(c,r) = fold over emissions w/ r ∈ to e. list = scope-path order; set = dedup; attrs = recursive merge, same leaf twice = error; one = exactly 1 else error.
- classes: branches list (single attrset = 1 branch); per scope ≤1 matching branch else error. ms(C,s) = content modules + forwarded. into (renArgs // {outputs}) ms → keys: class K ⟹ forward module to nearest ancestor-or-self s' w/ K-branch, (K,s')≠(C,s); channel ⟹ emission at s; else top-level output.
- outputs: recursive merge only on overlapping keys; leaf conflict = error. channel `into` at receiver r: `into renArgs pool` → keys same rules.

## CONTRACT AMENDMENTS v1.1 (supervisor ruling on vic/reviews/gate-plan-1.md; these OVERRIDE CONTRACTS above)
- A1 attrs fold: error only on UNEQUAL leaves (fleet.md:454 agenix.url from 5 hosts). leaf = non-attrset ∨ derivation ∨ has `_type`. recurse only when both sides plain attrsets.
- A2 field values: computed via user `lib` (nixpkgs lib passed to `load`): `(lib.modules.mergeDefinitions [kind name field] type defs).mergedValue`, defs = given value or option default ⟹ submodule defaults filled (fleet.md:124,363). Ren core never imports nixpkgs.
- A3 `is = K`: fields transitive through is-chain; below/spawns NEVER inherited (fleet.md:87).
- A4 spawns key ∉ below = named error (row L458). default children of K = instances of exactly `ren.K` (not subkinds).
- A5 `within` = STRICT ancestors (gen-select match.nix:122). no ancestor-or-self.
- A6 content fn vs bare fn: attrspat test `builtins.match ".*<attrspat.*" (builtins.toXML f) != null` (gate measured: functionArgs = {} for both `{ ... }:` and `final: prev:`).
- A7 `same`: v1 compares `__id`; gen-schema id_hash = DEFER (unproven, fleet.md:102). comment cites.
- A8 forward with no target scope = named error. `one` fold lazy (forced only when pool consumed). exclusion beats inclusion.

## LADDER (br epic ren-ren-impl-ly1). each rung = lib file + nix-unit tests + neg control.
R0 scaffold: flake.nix(gen input) default.nix Justfile shell.nix treefmt templates/ci harness, 1 smoke test.
R1 kinds+instances · R2 scopes · R3 predicates · R4 activation · R5 folds · R6 content+pools · R7 classes+forward+outputs · R8 load/mkFlake fixpoint · R9 templates/fleet (fleet.md verbatim-ish) + stub inputs · R10 fleet expected-result rows (fleet.md:433-463) as tests.

## GEN-FIT (opus lawyer, gen bcbc5ca, eval-proven on toy input)
- USE gen.scope.mkKinds/mkKind + gen.scope.eval: spawns builder writes own id ⟹ Ren mints `bare@parent`. gen `mintAttachmentId` adds @parent only if >1 parent (build-nodes.nix:342).
- USE gen.select.matches sel id ctx (match.nix:86); Ren supplies ctx {data parent children ancestors siblings}. gen kind/subkind need gen-schema minted kinds (constructors.nix:52) ⟹ Ren uses `when` for kind tests unless kinds minted via gen-schema.
- USE gen.scope.folds.{list one same mergeAttrs byKey} `fold key vs` (folds.nix:426). set = glue (unique).
- USE gen.graph.topoOrder {} { nodes; edges = n: [..]; } → {ok order} | {ok=false cycles} (stratification).
- UNPROVEN: gen.schema id_hash (`same`), gen.delivery.realize. forwarding = GAP (extraModules = inlet only).
- fleet.md L489 wrong: one/mergeAttrs exist as named gen folds.

## DEFER / GEN CANDIDATES (do not touch gen yet)
- gen-scope README:198-215 `mkKind { } "name"` 2-arg ≠ code 1-arg (cascade.nix:363). doc bug.
- excludes: gen-aspects meta.drop README:39 has no impl. Ren glue in activation.nix.
- forwarding: gen-delivery extraModules inlet; Ren glue in classes.nix.
