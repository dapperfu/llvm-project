# e200/VLE plan progress log

Tracks completion of the TODOs in `plans/ppc-e200-vle-toolchain.md` (the plan
file itself is not edited).  Each entry names the commits that completed it.

- [x] save-plan: plan committed as `plans/ppc-e200-vle-toolchain.md` on
  branch `ppc-e200-vle` (95e8dfdabc85).
- [x] m0-setup: rules submodule + .gitignore (7478e426a482), gcc submodule
  (2dcdf45a2f5d); `reference/`, `S32DS/` excluded locally; `build-e200`
  configured; baseline recorded in `baseline.md` (0 failures in check-llvm,
  check-clang, check-lld).
- [x] m1-audit: probes (a67ea2a77ca5), tools (1c18fb2bb53e), Table B-2
  (1c9545bd9c20), core extras (2ff751cb2393), capability matrix
  (9dc47559932d), inventory (6848ba4bc00a), source register (09332fe43721),
  GNU behaviour (c86051a4d0a5), audit (c8477013bcc7), discrepancies
  (895cfe89007c).
- [x] m2-registry: TargetFeaturesEmitter aliases/descriptions (afe613680cc4),
  e200 features and processors (f958acfcb7f8), subtarget validation
  (bbcd2e5330d7, 7047086f2138), TargetParser + unit test (93c3a01b73ec),
  Clang macros/validation (ac3f000c7f65), driver/-mvle/feature listing
  (fe320529df6f).  Milestone run: check-llvm 43,940 passed, check-clang
  50,772 passed, check-lld 2,172 passed, 0 failures.
- [ ] m3-booke-isa
- [ ] m4-vle-encoder
- [ ] m5-disasm
- [ ] m6-extensions
- [ ] m7-codegen
- [ ] m8-link-runtimes-lldb
- [ ] m9-conformance
- [ ] m10-docs-acceptance
