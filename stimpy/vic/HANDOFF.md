# stimpy HANDOFF
UPDATED: 2026-10-19 s1 end (opus-5-5 PM; agents: opus critics/view/kernel/triage, sonnet scaffold/folds/pred/template/tests/e2e, haiku recon)
STATUS: DONE. br epic stimpy-xjt closed (.1-.10). main = linear jj, not pushed.
VERIFIED (main, 2026-10-19): `nix-shell ./shell.nix --run just ci` → 208/208 (lib 105 + template tier1 103). `just e2e` → 23/23 (real inputs, templates/fleet/flake.lock lock-walk).
LAW: vic/fleet-stimpy.md = fleet.md v30 + "Stimpy corrections" C1-C12. C8-C12 = template bugs found by e2e.
DESIGN: vic/notes/stimpy-design.md (QUORUM RULINGS, INTERNAL API, evalFleet RESULT).
OPEN FOR VIC: review C1-C12 · C5 check lazy · set fold order = traversal · function-kind when = filter · includes act in subtree (nginx in ci) · into runs on empty ms · into-emissions skip channel at · template flake.lock stimpy node = local path placeholder · E2E-SKIP droid/terranix/aerospace/htop/docker · test files >100 lines · GitHub CI never run.
NEXT: vic review template modules/ split (vic/notes/template-layout.md); then ren same layout. lib/ manual imports: vic ruling.
