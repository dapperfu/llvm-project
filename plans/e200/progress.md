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
- [x] m3-booke-isa: strict category gating + embedded wait (4ee1f90f5d14),
  e200 SPR mnemonics (08afd8cb9937), 64-bit instruction rejection (this
  commit).  `.machine`: NXP GNU as 2.28 accepts any argument and ignores it
  (probes/out/p01-directives.txt); LLVM already parses and ignores it, so
  behaviour matches and no change was made.  Known gaps: `mbar` disassembles
  as `eieio` and `msync` prints as `sync` (same encodings; round-trip safe).
- [x] m4-vle-encoder: probes P13/P14 (6b26b2c90ffd), differential tools
  (932164c1e282), ELF constants (9765f9dbf3e0), "v" section flag
  (5775006b710e), fixups/relocations/@sda21 (2b5964ad5d00), Book E gaps found
  by the differential run: dcbtls/dcbtstls/dcblc (2459c2754eea), mcrxr
  (273117877686); formats and operands (349b427719f1); instructions by form
  4006cc9da267 (branches) through 5743c6e011bf (X/XL); VLE shared table and
  filter (12f647d75ecb), section-driven mode switching (bd45eb1c24eb), se_nop
  padding (cf380bc41cea), SHF_PPC_VLE marking and apuinfo (3988fbc01f94),
  simplified mnemonics (085e4314a2e7).  All 133 Table B-2 e_/se_ mnemonics
  assemble byte-identically to NXP GNU as 2.28 (tools/diff_mc_vs_gnu.py over
  P03/P13; only D11 and D14 differ by decision); relocations match P04 except
  D1.  Design note: the plan's VLEValid TSFlags bit is a generated searchable
  table (PPCInstrVLEShared.td) because TableGen cannot add fields to existing
  definitions.  Checkpoint after 29 commits: check-llvm 43,961, check-clang
  50,772, check-lld 2,172 passed; 16 failures in the sandboxed run (crash
  reporting, signal handling) all pass when rerun outside the sandbox.
- [x] m5-disasm: VLE decoding with the Table B-2 shared filter
  (8373683ae474), CR1-3 branch printing (e5838dd9e605), per-section VLE
  disassembler and apuinfo-derived features in llvm-objdump (25734310ada8),
  ObjectYAML flags (ea29d1b2a577), llvm-readobj flags and apuinfo notes
  (00713b18d24c), existing sections marked VLE as GCC emits (20f098f780de).
  Every M4 form test round-trips through the disassembler.  The halfword
  sweep (tools/vle_length_sweep.py, probes/out/m5-llvm-length-sweep.txt) has
  0 length mismatches against the NXP map; the only differences are the
  undocumented evmhusi and se_rfgi (discrepancies D19).
- [ ] m6-extensions
- [ ] m7-codegen
- [ ] m8-link-runtimes-lldb
- [ ] m9-conformance
- [ ] m10-docs-acceptance
