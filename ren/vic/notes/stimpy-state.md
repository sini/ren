# stimpy-state — extract of /home/vic/hk/ren-and-stimpy/vic (2026-10-19, read-only)

Src read: vic/HANDOFF.md (full), vic/state.md (full), ls -laR (head -80), vic/notes/* (first 40 lines each), find *.nix, vic/fleet.md vs fleet-v29.md headings. Not read: fleet.md / fleet-v28.md / fleet-v29.md bodies.

## HANDOFF

FACTS (verbatim, HANDOFF.md):
- UPDATED: 2026-10-18 night
- DOING: "Ren surface lang design. READ-ONLY: syntax in chat, NO impl. Every reply shows full fleet (1 example per capability, no repeats)."
- CURRENT: "vic/fleet.md = v30 = genie v29.A adopted (below/spawns on parent side like gen-scope, same kept for identity, anyOf, data collectors = channels with into, manifest from nixos collector). backups: fleet-v28.md (likely revert), fleet-v29.md."
- CURRENT (cont): v29 = reduced surface (Gen terms: classes/channels/aspects, includes/excludes, below/spawns, and/any/not/has/within/is; refs are predicates). v28 = genie v27.A (attrs recursive merge, folds usable in into, `anywhere` predicate, stratum-3 per collector branch, guarded forward on scope data, flake-file fetches only active inputs).
- NEXT-CMD: "vic annotates fleet.md. Apply notes, remove them, bump version. Reply shows fleet."
- THEN: "vic annotates fleet.md (vic: comments / > VIC:). Apply notes, remove them, bump the version."
- OPEN (verbatim): "forwarding on Gen (2-pass extraModules) unproven · has → gen-program UNVERIFIED · omit = Ren glue · per-kind collectors on gen-delivery realize untested · stage lacks microvm.nixosModules.host import (dup risk per guest) · namespaces (gen-link) later"
- FILES: "vic/fleet.md · scratchpad backups fleet-v15.md, fleet-v1{6,7,8}-vic-notes.md · vic/notes/ren-on-gen.md · vic/notes/ren-soundness.md · ren-design.md STALE"
- FILES (cont): "ren/ templates/ tests/ Justfile = unwanted impl, uncommitted; deletion asked, no answer."
- BURN: "opus-5-5 + haiku/sonnet readers. nothing committed."
- REV LOG: v30 genie v29.A · v29 exploration reduced surface (backup fleet-v28.md) · v28 genie v27.A · v27 hmPlatform, meta emission, templates+CI coverage, full matrix · v26 genie v25.A + flake-file + feature requests · v25 no provides-to, Den coverage table · v24 helpers + formatting · v23 approvals, strata table, vm-host · v22 sini review · v21 sini audit fixes · v20 cascade, colmena makeHive fold, droid phone kind · v19 colmena 2nd output, typed knob · v18 target = collector or list of collectors · v17 guest = own kind (ren.guest.ci.on); unless P any predicate · v16 1 example/capability · v15 omit, has, spawn exact kind, landing 1-4 · v14 same, at activates
- Note: HANDOFF says REV LOG "vic removed it from fleet.md, keep here".

## DECISIONS/RULINGS by vic

- HANDOFF.md VIC RULINGS (verbatim): "feature w/o at fires where taken · omit = opposite of take."
- HANDOFF.md (verbatim): "v22: declines, signal fold, into reads pools+outputs APPROVED. PENDING: is; declines removal (reverses approval)."
- HANDOFF.md (verbatim): "v26: genie fork ADOPTED, machine kind ADOPTED, outputs = top-level options (no flake. prefix)."
- HANDOFF.md FILES (verbatim): "ren/ templates/ tests/ Justfile = unwanted impl, uncommitted; deletion asked, no answer." (vic asked deletion; no answer recorded)
- state.md (verbatim): "MISTAKE: implemented kernel+fleet unasked (vic: design=read-only). mem design-phase-read-only."
- state.md (verbatim): "s1 end: vic picked v10 base; v11 fixes in HANDOFF."
- Not a ruling but recorded as open: ren-on-gen.md RISKS: "Spec ambiguity: fleet.md:44-45 'Hosts in one env share that env's scope'. ... Vic to pick."

## PROTOTYPE CODE

- .nix files under /home/vic/hk/ren-and-stimpy (excl .git): NONE (find returned 0).
- .nix files under /home/vic/hk/ren (excl .git, .jj): NONE (find returned 0).
- /home/vic/hk/ren/{ren,templates,tests,Justfile}: do not exist (ls error). HANDOFF calls "ren/ templates/ tests/ Justfile" unwanted impl, uncommitted. Location not confirmed on disk.
- state.md says kernel+fleet implemented in s1 (MISTAKE). No such code found in either dir.
- Doc-only notes (not code): vic/notes/ren-design.md (2 nouns, 4 fields; claims "code: `ren/` (kernel = builtins only...)", "run: `just test` (25 oracles...)"; HANDOFF: STALE), vic/notes/ren-on-gen.md (Gen mapping, read-only survey), vic/notes/ren-soundness.md (soundness audit of one-noun draft).

## OPEN ITEMS

- vic annotates fleet.md (> VIC: lines) · status: pending · evidence: HANDOFF NEXT-CMD.
- Apply vic notes, remove them, bump version · pending · HANDOFF NEXT-CMD/THEN.
- is (subtype) · PENDING vic ruling · HANDOFF VIC RULINGS.
- declines removal (reverses v22 approval) · PENDING vic ruling · HANDOFF VIC RULINGS.
- fleet-v28.md revert · "likely revert" · HANDOFF CURRENT.
- forwarding on Gen (2-pass extraModules) · unproven · HANDOFF OPEN.
- has → gen-program · UNVERIFIED · HANDOFF OPEN.
- omit = Ren glue · HANDOFF OPEN.
- per-kind collectors on gen-delivery realize · untested · HANDOFF OPEN.
- stage lacks microvm.nixosModules.host import (dup risk per guest) · HANDOFF OPEN.
- namespaces (gen-link) · later · HANDOFF OPEN.
- ren/ templates/ tests/ Justfile deletion · asked, no answer · HANDOFF FILES.
- ren-on-gen GAP 1: delivery nodes = one registry; user scopes not nodes; blocks #10, #11 · gap (ren-on-gen.md).
- ren-on-gen GAP 2: flake output path class-hardcoded (flakeModules/default.nix:46,513; defect bead den-hoag-es9g) · gap.
- ren-on-gen GAP 3: no `drop` in Gen (only README terminology, gen-aspects/README.md:39); blocks #5c, #13b · gap.
- ren-on-gen GAP 4: two predicate vocabularies (guard.nix pred vs gen-select sel.*) · gap.
- ren-on-gen RISK: spec ambiguity hosts-in-env scope (fleet.md:44-45) · vic to pick.
- ren-on-gen RISK: mixed formals `{ host-addrs, lib, ... }` · UNVERIFIED end-to-end.
- ren-on-gen RISK: perf O(n²) fleet pool reads · no measurement.
- ren-on-gen RISK: cross-terminal config cycle = uncatchable infinite recursion (#9).
- ren-soundness H1–H8 (visible in 40 lines; H9–H10 not read): classify not total/disjoint · proposed fix stratified semantics · no status recorded in file.
- ren-soundness: "NO line cites yet (PDFs not on disk). TODO: pull into haiku notebook, add `paper:line`." · open.
- ren-design.md · STALE per HANDOFF.

## fleet.md vs fleet-v29.md heading diff

Method: rg -n '^#' on both. v30 = fleet.md, v29 = fleet-v29.md. Heading text only.

- L1 title: v30 "# Ren fleet demo — v30 (2026-10-19) — EXPLORATION: reduced surface (genie v29.A adopted)" / v29 "# Ren fleet demo — v29 (2026-10-19) — EXPLORATION: reduced surface".
- v30 ADDED L5 "## What changed from v29 (genie, v29.A)" (absent in v29).
- v30 L31 "## What changed from v28" = v29 L5 "## What changed from v28" (moved +26).
- v30 L81 "## Vocabulary (v29.A)" / v29 L55 "## Vocabulary (v29)" (label suffix changed).
- L107 "## Fleet" / v29 L78 "## Fleet".
- L420 "## Evaluation order (strata)" / v29 L406 same.
- L431 "## Expected result (new and changed rows only; v25's other rows stand)" / v29 L417 same.
- L467 "## Gen mapping" / v29 L447 same.
- L499 "## Den coverage" / v29 L478 same.
- L547 "## Den templates and CI tests vs Ren" / v29 L526 same.
- L589 "### Den behaviours Ren refuses (by design)" / v29 L568 same.
- L600 "## Den feature requests vs Ren" / v29 L579 same.
- L608 "### Already expressible in Ren (no change)" / v29 L587 same.
- L656 "### Possible, but Ren would need a change" / v29 L635 same.
- L671 "### Not in Ren, by design or outside its reach" / v29 L650 same.
- L676 "## Open" / v29 L655 same.
- Heading set diff: +1 heading in v30 ("What changed from v29 (genie, v29.A)"); 1 label changed ("Vocabulary (v29.A)" vs "Vocabulary (v29)"); 1 title changed (adds "(genie v29.A adopted)"). All other headings identical text; line-number offsets v30 minus v29: +26 (Vocabulary, What changed from v28), +29 (Fleet), +14 (Evaluation order, Expected result), +20 (Gen mapping), +21 (Den coverage through Open).
- v30 body text claims (L1-3, verbatim): "v29.A = genie's fork of vic's v29 (gist `fbc69bfc`)." · "**The previous version is backed up as `vic/fleet-v28.md`**, and we may revert to it." (v30 description, not a heading; included for context.)
