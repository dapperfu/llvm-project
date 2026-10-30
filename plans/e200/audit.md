# Repository audit (deliverable A, expanded)

Base: upstream LLVM `24b1941da3f6`.  Paths are relative to the repository
root; line numbers refer to that base.

## Build and languages

- CMake + Ninja monorepo (C++17, TableGen, lit/FileCheck, gtest unit tests).
- Projects used: llvm, clang, lld, lldb (no Python/libedit on this host),
  compiler-rt and libunwind via a separate runtimes build.

## PowerPC target registry

- `llvm/lib/Target/PowerPC/PPCFeatures.td`: all SubtargetFeatures and the
  `Directive` class (L18-47).  Relevant: `FeatureSPE` (implies
  `FeatureHardFloat`, L81), `FeatureEFPU2` (implies SPE), `FeatureBookE`
  (implies `FeatureICBT`), `FeatureMSYNC` (implies BookE), `FeatureE500`
  (L139, attached to no processor), `FeatureISEL`, `FeaturePPC4xx`.
- `llvm/lib/Target/PowerPC/PPCProcessors.td`: `e500` (L75-78: BookE, ICBT,
  ISEL, MFTB, MSYNC, SPE), `e500mc`, `e5500`, `440`, `450`, `a2`.  No e200.
- `llvm/lib/Target/PowerPC/PPCTargetParserDef.td` includes PPCFeatures.td and
  PPCProcessors.td to generate `PPCGenTargetFeatures.inc`
  (`llvm/include/llvm/TargetParser/CMakeLists.txt` L7-8) used by
  `llvm/lib/TargetParser/PPCTargetParser.cpp` (`getPPCDefaultTargetFeatures`).
- `llvm/include/llvm/TargetParser/PPCTargetParser.def`: CPU list for
  `__builtin_cpu_is` (`8548`, `e500`, `e500mc`, `e5500` at L112-124).
- `PPCTargetParser.cpp` L57 normalizes `8548` to `e500`; L133-137 FIXME forces
  `spe` for `8548`.
- `ProcessorAlias` is handled by `SubtargetEmitter.cpp` L315-320 (backend)
  but not by `TargetFeaturesEmitter.cpp` (TargetParser).
- `PPCSubtarget.cpp` L82-84 is the only C++ CPU-name check (`powerpcspe`
  subarch selects `e500`); L106-114 enforce SPE vs FPU/Altivec/64-bit.

## Instruction definitions

- `PPCInstrFormats.td`: `I<>` is `bits<32>`, `Size = 4`; `I2<>` is 8 bytes.
  No 16-bit format.
- `PPCInstrSPE.td`: ~256 defs in DecoderNamespace `SPE` under
  `Predicates = [HasSPE]` (L130-812).
- `PPCInstrInfo.td`: Book E instructions `MBAR` (L4519), `WRTEE[I]`
  (L4537-4547), `TLBSX/TLBIVAX/TLBRE/TLBWE` (L4658-4671, `IsBookE`), `RFI`,
  `RFCI` (`IsBookE`), `RFDI`/`RFMCI` (L4694-4697, `IsE500`), `MFDCR`/`MTDCR`
  (L4699-4702, `IsPPC4xx`), `LSWI`/`STSWI` (L4500-4506, ungated), `WAIT`
  (L4516, ungated), `MFPMR`/`MTPMR` (L2934-2937, ungated), `DCBA` (L1988,
  ungated), `LBARX` family (`HasPartwordAtomics`), `ICBTLS` (`HasICBT`).
- Classic FP instructions are gated with `let Predicates = [HasFPU]` blocks
  (L1558, L2223, ...).
- SPRs are immediates (`i32imm:$SPR`); names come from `InstAlias`
  (`mflr`, `mfpid`, ...).

## Registers, ABI, ISel

- `PPCRegisterInfo.td`: `SPERC` S0-S31 = R + H halves (L57-62, L154-159),
  `SPEFSCR` SPR 512, DWARF 1200+N for SPE.
- `PPCCallingConv.td` / `PPCCallingConv.cpp` L143-194: SPE f64 split across
  GPR pairs; CSR_SPE S14-S30.
- `PPCISelLowering.cpp` L203-212: SPE f32 in GPRC, f64 in SPERC unless
  `hasEFPU2()`; SETCC on SPE floats is Custom (softened for NaN/Inf).
- `PPCSubtarget.h` L186-188: stack alignment always 16.
- `PPCRegisterInfo.cpp` L365-376: r13 reserved as SDA pointer; no SDA
  lowering exists.

## MC layer

- `AsmParser/PPCAsmParser.cpp`: directives `.word .llong .tc .machine
  .abiversion .localentry .gnu_attribute` (L1682-1695).  `.machine` is a
  FIXME no-op (L1742-1766).  `Match_MissingFeature` error L1307.
- `Disassembler/PPCDisassembler.cpp` L362-407: 8-byte prefixed path, then
  `DecoderTableSPE32` if `FeatureSPE`, then `DecoderTable32`; no 2-byte path.
- `MCTargetDesc/PPCFixupKinds.h`: br24, br24_notoc, brcond14, br24abs,
  brcond14abs, half16, half16ds, pcrel32/imm32/pcrel34/imm34, nofixup,
  half16dq.  `PPCAsmBackend.cpp`: no relaxation; `writeNopData` writes
  `0x60000000` only; InfosBE/LE omit `half16dq`.
- `PPCMCAsmInfo.cpp`: `MinInstAlignment = 4`; no `@sdarel`/`@sda21`.
- `PPCELFObjectWriter.cpp`: no SDAREL/EMB/VLE relocation emission.

## Object format and tools

- `llvm/include/llvm/BinaryFormat/ELFRelocs/PowerPC.def` L83-156: 0-37,
  67-96, 248-252 only.  `ELF.h`: no `EF_PPC_*` (ppc32), `SHF_PPC_*`,
  `PF_PPC_*`.
- `llvm/lib/Object/ELFObjectFile.cpp` L390-404: `getFeatures` returns empty
  for EM_PPC; L413-415 `tryGetCPUName` returns `"future"`.
- `llvm/tools/llvm-readobj/ELFDumper.cpp`: no PPC e_flags or section flags.
- `lld/ELF/Arch/PPC.cpp`: ADDR/REL/TLS/PLT relocations, TLS relaxation,
  `PPC32LongThunk`/`PPC32PltCallStub` (`Thunks.cpp`); no `calcEFlags`, no
  section-flag policy.

## Clang

- `clang/lib/Basic/Targets/PPC.h` L172-173: `ArchDefineE500` for
  `8548`/`e500`; `PPC.cpp` L42-91 `handleTargetFeatures`; L287-463
  `getTargetDefines` (`__SPE__`, `__NO_FPRS__`, `_SOFT_FLOAT`, ...); L536-605
  `initFeatureMap`.
- `clang/lib/Driver/ToolChains/Arch/PPC.cpp` L22-35 `getPPCAsmModeForCPU`
  (`-many` for all embedded CPUs), L38-53 features, L107-133 float ABI
  (default hard).
- `clang/include/clang/Options/Options.td` `m_ppc_Features_Group`
  L6162-6249: `-mspe`, `-mefpu2`, `-misel`, ...; no `-mvle`.
- `clang/lib/Driver/ToolChains/BareMetal.cpp` L46-49 handles
  `powerpc*-unknown-eabi`; multilib flags only for RISC-V/ARM/AArch64.
- `clang/tools/driver/cc1_main.cpp` L202-212: `--print-enabled-extensions`
  for AArch64/RISC-V only.

## Runtimes and LLDB

- compiler-rt builtins: generic soft-float sources for `powerpc` (no
  PowerPC-32-specific files).
- libunwind `Registers.hpp` `Registers_ppc`: classic GPR/FPR/VR; no SPE upper
  halves; `UnwindRegistersSave.S`/`Restore.S` use Book E encodings only.
- LLDB `ArchSpec.cpp` L191-216: ppc601..ppc970 cores only; register contexts
  for ppc64le only; `EmulateInstructionPPC64` handles ppc64 prologues.

## Execution engines

- No machine-code ISA simulator in the tree (`llubi` interprets LLVM IR).
  Per the plan, none is introduced.

## Technical debt found

- `FeatureE500` unattached; `RFDI`/`RFMCI` unreachable for `-mcpu=e500`.
- `getFixupKindInfo` arrays omit `fixup_ppc_half16dq`.
- `.machine` ignored.
- SPE instruction availability and SPE float ABI are one feature.
