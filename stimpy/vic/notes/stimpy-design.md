# stimpy design — Ren on nixpkgs lib (2026-10-19, opus-5-5)

LAW = `/home/vic/hk/stimpy/vic/fleet-stimpy.md` (= fleet.md v30 + section "Stimpy corrections" C1-C7). Cite `fleet.md:NNN` (same line numbers) or `C<n>`. NO Gen code: never read ~/hk/gen*.
Stimpy = flake. ONLY input `github:nixos/nixpkgs`. NO Gen. Kernel uses `nixpkgs.lib` only (no pkgs).
Kernel has NO domain words: no host/user/nixos. All vocab from template (`templates/fleet`).

## Surface (what template writes)

```nix
# templates/fleet/fleet.nix  — a module fn; `ren` = processed view
{ ren, lib, inputs, ... }: let … in { ren.classes = …; ren.kinds = …; ren.channels = …; ren.aspects = …; ren.<kind>.<name> = …; }
# templates/fleet/flake.nix
outputs = inputs: inputs.stimpy.lib.mkFlake inputs ./fleet.nix;
```
fleet.md:134 writes `ren.lib.mkFlake inputs { … }` w/ free `ren`; fleet.md:579 "`ren.lib.mkFlake` is a module set; `evalModules` it". ⟹ body = module, `ren` = `_module.args.ren`.

Public lib (`stimpy.lib`): `mkFlake inputs module` → outputs attrset. `evalFleet inputs module` → `{ outputs; scopes; active; pools; landed; }` (inspection; tests). Inside view: `ren.lib.{and anyOf not when within has is same}`, `ren.lib.fold.{list set attrs one}` (fleet.md:111-112). NO `any` export (fleet.md:15,462).

Reserved (fleet.md:21-25): ren top keys `classes kinds channels aspects lib`; kind keys `below spawns is`; aspect keys `at includes excludes`; class branch `at into`; channel `fold at to into`; bindings `parent outputs`.

## Data model (view `ren`)

- KIND REF `ren.kinds.K` = option type (`lib.mkOptionType`, check = instance of K or subkind) // `{ __ren = { ref = "kind"; kind = "K"; }; }`. Usable as field type (fleet.md:211,223) AND predicate (fleet.md:122).
- INSTANCE `ren.K.n` = typed fields (evalModules submodule from kind fields) // `{ name = n; __ren = { ref = "inst"; kind = "K"; id = "<family>/<n>"; }; }`. `ren.K` = ONLY instances declared under `ren.K` (not subkinds) — else ci spawns under staging env directly (fleet.md:215,272).
- Kind field forms: bare type ⟹ required option; `lib.mkOption` value ⟹ as is. `is = K` ⟹ fields = K fields ∪ own; `below`/`spawns` NOT inherited (fleet.md:87).
- FUNCTION KIND `replica = { db, region }: when p { }` (fleet.md:249): arg names = ref fields typed by kind of same name; body fields; `when p` = spawn filter (instance w/o p never spawns). DECISION(flag vic): filter not error.
- AT-MOST-ONE name per is-family: `ren.host.ci` + `ren.guest.ci` ⟹ eval error (fleet.md:448).
- IDENTITY `same a b` = `a.__ren.id == b.__ren.id` (fleet.md:102, needs no scope).
- ASPECT REF `ren.aspects.a` = user attrset // `{ __ren = { ref = "aspect"; name = "a"; }; }`.

## Stratum 0 — scopes (fleet.md:424)
- ROOT kinds = no `below` lists them AND own `below` non-empty (fleet = root; channel/group/machine scope-less, fleet.md:29). DECISION.
- Kind graph via `below`: cyclic/self ⟹ error at registration (fleet.md:12,424). `spawns` key ∉ `below` ⟹ error (fleet.md:85,458).
- Children of scope s for C ∈ below: `(spawns.C or (_: ren.C)) s` → attrset of instances of EXACT kind C (else error). Instance at most once per path (fleet.md:88).
- Children order = attrNames (sorted) ⟹ deterministic scope-path order (fleet.md:436).
- SCOPE value = bindings attrset: per path instance (root→self), bound under its kind + every superkind (nearest wins: ci binds host=ci, fleet.md:438) + `parent` (parent instance) + function-kind arg fields (`db`,`region`). Each bound instance carries `__ren.scope` = its scope on THIS path (for `is`). `__ren = { ref="scope"; path; kind; id; }`.
- path id string `fleet:main/environment:prod/host:lb/user:alice`.

## Predicates (fleet.md:101) — data AST, evaluated `match ctx pred scope`
kind ref: scope kind = K or subkind · inst: scope's own instance same · aspect: active at scope (stratum 1) · scope `e`: same scope · `and`/`anyOf`/`not` · `when f`: f bindings · `within P`: PROPER ancestor matches · `has P`: some child matches. `is P x` = P matches `x.__ren.scope`; no scope ⟹ error (fleet.md:105). ALL refs walkable ⟹ stratification static.

## Stratum 1 — activation (fleet.md:97-98,425)
active(a,s) = (at_a(s) ∨ ∃b active at s or ancestor(s), a ∈ b.includes) ∧ ¬(∃b active at s or ancestor(s), a ∈ b.excludes). No `at` ⟹ only via includes (fleet.md:97).
Dep graph aspects: ref in `at` (polarity via `not`), includes(+), excludes(−). SCC w/ negative edge ⟹ error "not stratified" (fleet.md:104,425). Eval strata in topo order; positive SCC = monotone fixpoint.

## Stratum 2 — content (fleet.md:99-100,426)
Per active (a,s), key k ∉ reserved:
- k ∈ classes ⟹ module; LANDS at s iff some branch of class k matches s. Lands at none of a's scopes ⟹ error (fleet.md:100,595). Neither class nor channel ⟹ error (fleet.md:99,584).
- fn content: Ren supplies formals ∈ bindings ∪ pools; rest stays module args (`lib.setFunctionArgs`). Wrapped `{ key = "<a>@<path>"; _file; imports=[m]; }` (fleet.md:572).
- k ∈ channels ⟹ emission at s iff s matches channel `at` (default any, fleet.md:94). Content MUST be attrset-pattern fn (`builtins.toXML` shows `attrspat`), else error (fleet.md:450). Called w/ bindings ∪ pools ∪ `{ lib }`.
- POOL(c,r) = fold_c [ v(e) | e emits c, r matches `to e` ], ordered by scope path. Folds (fleet.md:96): list=ordered · set=unique (path order) · attrs=recursive merge, unequal leaf ⟹ error · one=exactly 1 else error (lazy, on read).
- Class/channel name clash ⟹ error (fleet.md:575). Kind/channel name ∈ module-arg names {lib config options pkgs modulesPath} ⟹ error (fleet.md:534). shortcut: fixed name list.

## Stratum 3 — collectors (fleet.md:427)
Per class k, branch i, scope s matching branch.at (>1 branch match ⟹ error "branches not disjoint", fleet.md:90): ms = landed(k,s) ++ forwarded(k,s). R = into (bindings ∪ pools ∪ {outputs}) ms. Per key of R:
- class j ⟹ FORWARD: module R.j appended to ms of (j, t), t = nearest ancestor-or-self scope where class j matches, t≠s if j==k (guest→stage, fleet.md:149-152,438). none ⟹ error.
- channel ⟹ emission at s (fleet.md:18,145-146).
- else ⟹ top-level output, merged `attrs` law across all (fleet.md:92,449,454).
Channel w/ `into`: once per receiving scope with non-empty pool (fleet.md:16,300-306).
`outputs` = final merged outputs (lazy). Branch whose `into` formals has `outputs` AND result keys name a class ⟹ error (fleet.md:427,457).
mkFlake result = merged outputs.

## Tests (nix-unit; names MUST start `test`, trap om nix-unit-collection-traps)
- lib: `tests/lib/*.nix` per stratum, tiny synthetic vocab (NOT fleet words) + negative control per rule (`expectedError`).
- template tier1: `templates/fleet/tests/*.nix`, evalFleet on real fleet.nix; inputs except nixpkgs = `throw "unfetched X"` ⟹ any forcing = loud fail. One test per fleet.md:431-463 row (scope/active/landed-key/pool level).
- template e2e: real inputs via template flake.lock; rows needing realized config. `just e2e`.
- every single test <1s (vic). e2e exempt like compile.

## Files (each <100 LOC post-fmt)
`flake.nix default.nix Justfile treefmt.toml .github/workflows/test.yml lib/{default,view,kinds,pred,scopes,activation,content,folds,collect,merge}.nix tests/lib/*.nix templates/fleet/{flake.nix,fleet.nix,tests/*.nix}`

## OPEN (flag vic, not blocking)
- function-kind `when` = filter vs error.
- includes/excludes subtree reading (fleet.md:98) — implemented literal: includer scopes + descendants.
- `within` proper-ancestor (htop fleet.md:346 needs only proper).

## QUORUM RULINGS (critic A nix-semantics + critic B law, 2026-10-19) — OVERRIDE above

- OPTION LAYOUT (A-F3, eval-proven): `options.ren` = submodule; declared `kinds classes channels aspects` = `lazyAttrsOf raw`; instances via `freeformType = lazyAttrsOf (lazyAttrsOf deferredModule)`. NEVER declare dynamic options as siblings of `kinds` (inf rec, proven). Typing per instance = own `lib.evalModules { modules = [ defs { options = fieldOpts; } ]; }` inside `_module.args.ren`. Args read at `result._module.args`, not `config._module`.
- KIND REF merge (A-F2): `merge = loc: defs:` head if all `__ren.id` equal else throw. NOT mergeEqualOption (cyclic graphs).
- RESERVED field names (A-F4): `config options imports _file key disabledModules freeformType name` + kind keys `below spawns is` ⟹ error at kind registration.
- `is` union = `superFields // ownFields` (A-F7).
- MODULE KEY = `builtins.toJSON [ aspectName scopePathList ]` (A-F8).
- CONTENT FN rule (A-F6): ok iff toXML shows attrspat OR `f ? __functionArgs` OR `f ? __functor`.
- MODULE-ARG clash list (A-F9): `lib config options pkgs modulesPath specialArgs name extendModules moduleType osConfig nixosConfig`. shortcut.
- ATTRS LAW (A-F1) in lib/merge.nix `mergeStrict loc defs`: 1 def ⟹ returned UNFORCED. ≥2: if all are attrs and none `lib.isDerivation` and none `? _type` ⟹ zipAttrs recurse; else leaf: all `==` head ⟹ head (drv == compares outPath); function leaf w/ ≥2 defs ⟹ conflict error w/ loc path. Used by fold `attrs` AND outputs merge.
- `into` result TOP-LEVEL KEYS must be static (A-F10); attrNames forced.
- `and` = left-to-right, stop at first false; `anyOf` stop at first true (B-2, C2).
- root kinds, bindings nearest-wins: see C3 C4. persist: C1.

## INTERNAL API (lanes code against this)
```
lib/default.nix  { lib }: { mkFlake = inputs: module: (evalFleet inputs module).outputs; evalFleet; }
lib/merge.nix    { lib }: { mergeStrict = loc: defs: …; }          # loc = list of strings for errors
lib/folds.nix    { lib, merge }: { list set attrs one }           # each = { __ren = { ref = "fold"; name; }; fold = loc: vs: result; }
                 list: vs · set: lib.unique vs (first occurrence order) · attrs: merge.mergeStrict loc vs · one: exactly 1 else throw "ren: <loc>: fold one got N"
                 vs arrive already in scope-path order.
lib/pred.nix     { lib }: { and anyOf not when within has is same; match; refsOf; }
                 match = ctx: p: scope: bool;  ctx = { activeAt = aspectName: scope: bool; children = scope: [scope]; ancestors = scope: [scope] (nearest first, proper); }
                 refsOf = p: [ { aspect = name; positive = bool; } ]   # walk AST for stratification
scope value     = bindings attrset // { __ren = { ref = "scope"; kind; id = pathString; path = [ { kind; name; } … ]; inst; }; }
```

## evalFleet RESULT (template tier1 tests code against this)
```
evalFleet inputs module = {
  outputs;                                  # merged top-level outputs (lazy leaves)
  scopes;     # id -> scope.  id = concatStringsSep "/" (map (p: "${p.kind}:${p.name}") path)  e.g. "fleet:main/environment:prod/host:lb"
  active;     # aspectName -> [ id ]  (scope-path order)
  landed;     # className -> id -> [ aspectName ]   (aspect content landed at that scope, path order of aspects = attrNames order)
  forwarded;  # className -> id -> [ fromId ]       (scopes whose into forwarded a module into (class,id))
  emitted;    # channelName -> [ id ]               (emitter scope ids, incl. into-emissions)
  pools;      # channelName -> id -> folded value   (receivers only; lazy)
  branches;   # className -> id -> branchIndex       (which branch matched)
}
```
