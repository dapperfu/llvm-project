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
- Decision: LLVM rejects `e_li` with a non-SDA21 symbolic operand
  ("relocation not representable in the LI20 field").

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
