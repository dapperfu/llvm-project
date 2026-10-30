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
- [ ] m2-registry
- [ ] m3-booke-isa
- [ ] m4-vle-encoder
- [ ] m5-disasm
- [ ] m6-extensions
- [ ] m7-codegen
- [ ] m8-link-runtimes-lldb
- [ ] m9-conformance
- [ ] m10-docs-acceptance
