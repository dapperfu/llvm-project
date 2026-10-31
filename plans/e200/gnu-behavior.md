# NXP GNU toolchain behaviour (M1 probe results)

Reference toolchain: NXP `powerpc-eabivle` GCC 4.9.4 (BLD 1607) and GNU
binutils 2.28 (see `source-register.yaml`).  Every statement below is backed
by a file in `probes/out/`, regenerated with `probes/run-probes.sh`.  These are
reference-implementation facts, not architecture authority; where they
disagree with a manual the disagreement is logged in `discrepancies.md`.

## Assembler encoding mode

- VLE is a **global, per-invocation mode** selected by `-mvle` (or a CPU flag
  such as `-me200z4` that implies it).  There is no per-section switching:
  with `-mvle`, Book E-only mnemonics (`addi`, `b`, `blr`, `lwz`, `rfi`, `sc`,
  `crand`, `mcrf`, `stmw`, ...) are rejected in every section; without it,
  every `e_`/`se_` mnemonic is rejected (`p02-sections.txt`,
  `p03-vle-acceptance.txt`).
- `.vle` and `.novle` do not exist ("unknown pseudo-op").  `.machine <x>` is
  accepted for any argument and has no observable effect
  (`p01-directives.txt`).
- In VLE mode the shared Book E encodings of VLEPEM Table B-2 are accepted
  (`add`, `lwzx`, `mflr`, `mtctr`, `isel`, `wrteei`, `mtmsr`, `tw`, SPE `ev*`,
  `efs*`, ...).  `nop` assembles to `se_nop` (0x4400).
- `-me200z4 -mno-vle` falls back to a minimal Book E table that rejects even
  `isel`, `rfdi`, `efs*` and cache locking.  `-me500x2` is the most complete
  Book E reference available (`p03-booke-acceptance.txt`).

## Section flags, notes and ELF header

- With `-mvle`, every section that receives an instruction gets
  `SHF_PPC_VLE` (readelf `V`), even one declared `"ax"`.  The `v` section flag
  letter is accepted and sets `SHF_PPC_VLE` on any section, including data
  (`.rodata_v,"av"`) (`p02-sections.txt`).
- VLE objects get a `.PPC.EMB.apuinfo` SHT_NOTE: name `APUinfo`, type 2, one
  word per APU.  VLE is `0x01040001` (ID 0x0104, rev 1, matching VLEPIM
  2.2.1).  With `-mhard-float` on e200z4 GCC adds `0x01010001` (ID 0x0101,
  EFS) (`p02-sections.txt`, `p11-*.o`).
- `e_flags` is 0 unless `-memb` is given, which sets `0x80000000`
  (`EF_PPC_EMB`).
- GCC output places VLE code in `.section ".text","axv"` and functions are
  `.align 1` plus `.p2align 2,,3` (`p11-z4-vle.s`).
- `.gnu.attributes` is always emitted; `Tag_GNU_Power_ABI_FP` reads "soft
  float" even with `-mhard-float` (single-precision values live in GPRs).
  `-mspe` code records `.gnu_attribute 8, 3` (vector ABI = SPE).

## Relocations (`p04-relocs.txt`, `p08-emb-relocs.txt`)

- VLE relocation numbers match VLEPIM Table 2-4: REL8 216, REL15 217,
  REL24 218, LO16A 219, LO16D 220, HI16A 221, HA16A 223, HA16D 224, SDA21 225.
- Field selection follows the instruction form, not the specifier:
  `e_lis`/`e_or2i`/`e_or2is`/`e_and2i.`/`e_and2is.` use the A split field,
  `e_add2i.`/`e_add2is`/`e_cmp16i` use the D split field.
- `e_add16i rD, rA, sym@l` and `e_lwz rD, sym@l(rA)` use plain
  `R_PPC_ADDR16_LO` at offset +2 (ordinary D-form field).
- `@sda21` on `e_add16i`, `e_li` **and** `e_lwz` gives `R_PPC_VLE_SDA21` at
  offset +0, against the section symbol.
- `@sdarel` gives `R_PPC_SDAREL16` (32) at offset +2.
- Book E mode: `@sda21` gives `R_PPC_EMB_SDA21` (109) at offset +0; `@sdarel`
  gives `R_PPC_SDAREL16` (32).
- `e_li rD, sym@l` is accepted and emits `R_PPC_ADDR16_LO` at +2, which would
  overwrite the split LI20 field (see discrepancies).

## Alignment, ranges, relaxation (`p05-align.txt`, `p06-relax.txt`)

- Alignment padding inside VLE sections is `se_nop` (0x4400) halfwords; a
  4-byte gap can also be filled by `e_nop` (0x1800D000) when written
  explicitly.  Section alignment follows the largest `.p2align` requested.
- No relaxation: out-of-range `se_b`/`se_bc` ("-256..254") and `e_bc`
  ("-32768..32766") are hard errors.  Odd branch targets are rejected
  ("1 is not a multiple of 2").

## Instruction length (`p12-length-map.txt`)

- An exhaustive sweep of all 65,536 first halfwords through NXP objdump
  (`-M e200z4,vle,spe,efs,efs2`) gives 41,132 decodable 16-bit and 11,840
  decodable 32-bit leading halfwords.  All 52,972 decodable cases satisfy:
  **32-bit iff `(halfword & 0x9000) == 0x1000`**, i.e. the top nibble is 1, 3,
  5 or 7; zero mismatches.  The remaining 12,564 halfwords are unallocated in
  this sweep (or not decodable with the fixed `se_nop` second halfword used).

## Special-purpose registers (`p09-spr.txt`)

- No symbolic SPR operands: `mfspr r3, hid0` is rejected.  Extended
  mnemonics are accepted and printed: `mfhid0`, `mtl1csr0`, `mfivpr`,
  `mfspefscr`.  SPR 568 prints as `mfiac8`.

## Compiler driver (`p10-macros.txt`, `p11-*.s`)

- `-mcpu=` accepts e200z0, e200z2, e200z3, e200z4, e200z6, e200z7 only;
  e200z1, e200z759 and e200z446n3 are rejected.  No `-mcpu` means e200z0.
- Every e200 CPU defaults to VLE: `__VLE__`, `__PPCVLE__`, `__NO_LWSYNC__`
  are defined unless `-mno-vle`.
- Common macros: `__PPC_EABI__`, `_CALL_SYSV`, `__NO_FPRS__`, `_SOFT_FLOAT`,
  `_SOFT_DOUBLE`, `__SIZEOF_LONG_DOUBLE__ 8`, `__BIGGEST_ALIGNMENT__ 16`,
  `PPC`, `__PPC`, `_BIG_ENDIAN`.  Per CPU: `__PPCE200Z<n>__`.
- `-mhard-float` removes `_SOFT_FLOAT` (keeps `_SOFT_DOUBLE`) and uses
  `efsadd` etc. for `float`; `-mspe` adds `__SPE__`.
- ABI: 8-byte stack frames are emitted (`e_stwu 1,-8(1)`), dynamic allocas are
  rounded to 16.  Soft-float `double` is passed in GPR pairs (r3:r4),
  `long long` skips to an odd-aligned pair (r7:r8), aggregates are passed by
  reference, small structs (8 bytes) are returned in r3:r4, larger ones via a
  hidden r3 pointer.  `long double` is 8 bytes.
- GCC VLE output mixes `e_`/`se_` forms with shared X-form instructions
  (`mullw`, `mulhwu`, `stwux`, `add`) and uses `e_la`, `se_mfar`, `se_mr`.

## Not determined

- SPE DWARF numbering for the upper GPR halves: the GCC sample did not save
  an upper half (`p11-spe-cfi.txt`); unresolved.
- Section naming for mixed Book E/VLE modules: GNU cannot assemble both
  encodings in one invocation, so there is no GNU precedent.

## VLE operands and simplified mnemonics (`p13-vle-edges.txt`)

- SCI8 values are synthesized with the lowest possible SCL: 0 is
  F=0/SCL=0/UI8=0, -1 is F=1/SCL=0/UI8=0xff, 0xffff00ff is F=1/SCL=1/UI8=0.
  Values with no SCI8 form give "illegal immediate value".  `e_mulli` and
  `e_rlwinm` have no record forms; `e_addi.`, `e_addic.`, `e_subfic.`,
  `e_andi.`, `e_ori.`, `e_xori.` exist.
- Ranges: `e_lis`/`e_or2i`/`e_cmpl16i` take 0-0xffff; I16A signed fields
  take -0x8000-0xffff; `e_li` takes -0x80000-0x7ffff; `se_li` 0-127; SD4
  displacements must be multiples of the access size; D8 is -128-127;
  BF32/BI32 name CR fields 0-3, `e_mcrf` takes CR fields 0-7.
- `se_addi rX,0` is accepted and adds 32 (see discrepancies D11).
- Accepted simplified mnemonics: `e_nop`, `se_nop`, `nop` (as `se_nop`),
  `e_subi`, `e_sub16i`, `e_sub2i.`, `e_sub2is`, `e_subic[.]`, three-operand
  `e_cmpwi`/`e_cmplwi`, `e_clrlwi`, `e_clrrwi`, `e_clrlslwi`, `e_rotlwi`,
  `e_rotrwi`, `e_extlwi`, `e_extrwi`, `e_inslwi`, `e_insrwi`, `e_crset`,
  `e_crclr`, `e_crmove`, `e_crnot`, `e_la`, `e_b<cond>[l] [crN,]`,
  `se_b<cond>`, `e_bdnz[l]`, `e_bdz[l]`, `e_bt`/`e_bf`, `se_bt`/`se_bf`.
- `e_sc [LEV]` is accepted (0x7C000048; see discrepancies D14).

## APU information (`p14-apuinfo.txt`)

- One APU word per instruction category, in first-use order, revision 1:
  `isel` 0x40, `mfpmr`/`mtpmr` 0x41, `rfmci`/`se_rfmci` 0x42, `dcbtls` 0x43,
  `ev*` 0x100, `efs*`/`efd*` 0x101, other `e_`/`se_` instructions 0x104.
  Shared Book E instructions such as `add` add nothing, in VLE mode too.
  `wait` records 0x100 (see discrepancies D16).
