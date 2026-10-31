# Discrepancies log

Disagreements between authoritative documents, reference implementations and
LLVM.  Each entry records the evidence and the decision taken; nothing here is
resolved by assuming the reference implementation is wrong.

## D1: VLE SDA21 on loads/stores

- VLEPIM Rev. 1 Table 2-5 note (p.2-8): loads and stores such as `e_lwz`
  "should use the EABI relocation R_PPC_EMB_SDA21"; R_PPC_VLE_SDA21 is for
  `e_add16i` (possibly rewritten to `e_li`).
- NXP binutils 2.28 emits R_PPC_VLE_SDA21 for `e_lwz rD, sym@sda21(0)`
  (`probes/out/p04-relocs.txt`).
- Decision: LLVM emits R_PPC_VLE_SDA21 only for `e_add16i`/`e_li`, and
  R_PPC_EMB_SDA21 for D-form loads/stores, as VLEPIM specifies; lld accepts
  both on loads/stores so NXP-assembled objects still link.  Revisit if
  NXP ld output proves the two are not interchangeable.

## D2: `e_li rD, sym@l`

- NXP binutils 2.28 accepts it and emits R_PPC_ADDR16_LO at offset +2, which
  overlaps the split LI20 immediate field (bits 11-15, 17-20, 21-31).
- VLEPIM defines no relocation for the LI20 field except via SDA21/split20.
- Decision: LLVM rejects `e_li` with a non-SDA21 symbolic operand ("invalid
  operand for instruction" at the operand).

## D3: e_lmv* mnemonic spelling and coverage

- e200z4RM Rev. 0 Table 3-4 (p.108-115) and e200z759n3CRM spell the loads
  `e_lmvgprw`, `e_lmvsprw`, `e_lmvsrrw`, `e_lmvcsrrw`, `e_lmvdsrrw`,
  `e_lmvmcsrrw`.
- NXP binutils 2.28 accepts `e_lmv*` but prints `e_ldmv*`, and rejects
  `e_lmvmcsrrw`/`e_stmvmcsrrw` entirely.
- Decision: LLVM uses the manual spelling as canonical and accepts `e_ldmv*`
  as an alias.  `e_lmvmcsrrw`/`e_stmvmcsrrw` are implemented from the manual
  (group 0b00111) and excluded from the differential suite.

## D4: dnh, e_dnh, se_dnh, rfmci, lbarx family

- Documented in e200z4RM §3.11.1, §3.12, §3.14 and the z759/z760 manuals.
- NXP binutils 2.28 rejects all of them with `-mvle -me200z4`
  (`probes/out/p03-vle-acceptance.txt`); `rfmci` is only accepted with
  `-me500x2`.
- Decision: implement from the manuals; differential tests skip them.

## D5: SPR 568 name

- ALTCTXCR on e200z1 (Fig 2-1 p.28) and e200z6 (Table 2-42); IAC8 on
  e200z4/z759/z760.  binutils prints `iac8` unconditionally.
- Decision: per-core SPR names in `PPCSystemOperands.td`.

## D6: e200z2 existence

- User statement: e200z2 does not exist as a core.
- NXP GCC accepts `-mcpu=e200z2` and DEVKIT has `MPC5748G/e200z2_3`.
- Decision: omitted (no manual); listed in plan section 8 item 1.

## D7: e200z6 VLE

- e200z6RM Rev. 0 (2004) never mentions VLE; NXP GCC enables VLE by default
  for `-mcpu=e200z6`.
- Decision: VLE unverified for e200z6, `-mvle` rejected.

## D8: Default encoding mode

- NXP GCC turns VLE on for every e200 `-mcpu`.  Plan decision: Book E unless
  `-mvle`, except VLE-only cores.  Documented as a migration note.

## D9: mfdcr/mtdcr in VLE mode

- VLEPEM Table B-2 lists `mfdcr`/`mtdcr` as available in VLE mode.
- NXP binutils 2.28 rejects them with `-mvle` (`p03-vle-acceptance.txt`).
- Decision: follow VLEPEM plus the per-core manual (`dcr` category) and
  accept them in VLE mode where the core supports DCRs.

## D10: Move-assist instructions in Table B-2

- VLEPEM Table B-2 lists `lswi`/`lswx`/`stswi`/`stswx` (category MA) as VLE
  instructions, but every e200 core manual lists string instructions as
  unsupported.
- Decision: per-core manuals win; capability-matrix marks MA unsupported.

## D11: `se_addi rX, 0`

- VLEPEM Rev. 0 Table A-1: OIM5 holds 1-32, encoded as 0-31.
- NXP binutils 2.28 accepts `se_addi 3,0` and encodes OIM5 = 31, an add of
  32 (`probes/out/p13-vle-edges.txt`).
- Decision: LLVM accepts 1-32 only and rejects 0.

## D12: `e_cmpwi`/`e_cmplwi` with CR0

- VLEPIM Rev. 1 Table A-23 maps `e_cmpwi cr0,rA,SIMM` to `e_cmp16i` and
  `e_cmplwi cr0,rA,UIMM` to `e_cmpl16i`, besides the `e_cmpi`/`e_cmpli`
  forms.
- NXP binutils 2.28 only implements the three-operand SCI8 forms: two
  operands give "missing operand" and `e_cmpwi cr0,3,0x7fff` "illegal
  immediate value" (`p13-vle-edges.txt`).
- Decision: LLVM matches GNU (SCI8 forms only), so every accepted input
  assembles to the same bytes.  The I16A fallback is not implemented.

## D13: `e_slwi`/`e_srwi`

- VLEPIM Rev. 1 Table A-23 lists them as simplified mnemonics of
  `e_rlwinm`; VLEPEM Rev. 0 Table B-2 defines them as X-form instructions
  (0x7C000070, 0x7C000470).
- NXP binutils 2.28 encodes the X forms (`p03-vle-acceptance.txt`).
- Decision: the X-form instructions, as VLEPEM and GNU agree.

## D14: `e_sc`

- NXP binutils 2.28 accepts `e_sc [LEV]` (0x7C000048, LEV in bits 20-26).
- No NXP manual in the source register documents `e_sc`; VLEPEM lists only
  `se_sc` and the shared `sc` is not in Table B-2.
- Decision: not implemented (undocumented instructions are unsupported).

## D15: efs* opcodes in VLEPEM Table B-2

- VLEPEM Rev. 0 Table B-2 gives every efs* row the extended opcode of the
  matching efd* instruction (efsabs 0x100002E4 = efdabs).
- SPEPEM Rev. 0 EFX opcode tables give efsabs 0x100002C4 (XO 708), as does
  LLVM's existing definition.
- Decision: SPEPEM is authoritative for SPE encodings;
  `tools/gen_vle_shared.py` subtracts 0x20 from efs* rows in 0x2E0-0x2FF.

## D16: `.PPC.EMB.apuinfo` contents

- NXP binutils 2.28 adds one APU word per instruction category used:
  ISEL 0x40, PMR 0x41, RFMCI 0x42 (also for `se_rfmci`), CACHELCK 0x43
  (`dcbtls`), SPE 0x100, EFS 0x101 (efs* and efd*), VLE 0x104 (other
  e_/se_ instructions); shared Book E instructions add nothing
  (`probes/out/p14-apuinfo.txt`).  It also records SPE for `wait`.
- `wait` belongs to the e200 WT/base set (e200z4RM Rev. 0 §3.13), not to SPE.
- Decision: LLVM follows the per-category rules but records no APU for
  `wait`, and emits the note only for e200 cores or VLE code so output for
  other 32-bit cores is unchanged.

## D17: VLE mode selection in the assembler

- VLEPIM Rev. 1 §2.2.2: instructions in SHF_PPC_VLE sections are VLE, Book E
  instructions live in sections without the flag.
- NXP binutils 2.28 treats `-mvle` as global: every section receiving an
  instruction is marked VLE; without it, VLE mnemonics are rejected even in
  sections declared with the `v` flag (`p02-sections.txt`).
- Decision: with the `vle` feature LLVM behaves like GNU `-mvle`.  Without it,
  on a core with `vle-isa`, entering a `v` section switches to VLE mode
  (VLEPIM), a superset that lets one object mix both encodings.

## D18: `mfpmr`/`mtpmr` on e200z4

- e200z4RM Rev. 0 §3.9 (p.97): no performance monitor (capability matrix
  E.PM unsupported).
- NXP binutils 2.28 accepts both for `-me200z4` (`p03-vle-acceptance.txt`).
- Decision: the core manual wins; LLVM rejects them for e200z4.
