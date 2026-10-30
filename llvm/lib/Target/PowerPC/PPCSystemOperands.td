//===-- PPCSystemOperands.td - e200 special-purpose registers -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Extended mnemonics (mf<spr>/mt<spr>) for the special-purpose registers of
// the NXP/Freescale e200 cores.  GNU as accepts and prints these spellings;
// symbolic SPR operands (mfspr r3, hid0) are not accepted by GNU as and are
// not provided here.
//
// SPR numbers and availability: e200z0CORERM Rev. 0 Figs 2-1/2-2 (p.32-33);
// e200z1RM Rev. 0 Table 2-15 (p.49-51); UM0434 Rev 2 Table 89 (p.98-100);
// e200z4RM Rev. 0 Table 2-15 (p.85-89); e200z6RM Rev. 0 Table 2-42
// (p.115-118); e200z759n3CRM Rev. 2 Table 16 (p.55-58); e200z760RM Rev. 2
// Table 2-15 (p.87-89).  SPRs that already have generic Book E mnemonics
// (srr0/1, esr, dear, dec, tcr, pid, sprg0-7, spefscr, ...) are not repeated.
//
//===----------------------------------------------------------------------===//

def IsE200 : Predicate<"Subtarget->isE200()">,
             AssemblerPredicate<(all_of FeatureE200)>;
// e200z4/e200z7 debug, machine-check and cache registers.
def IsE200Z4OrZ7
    : Predicate<"Subtarget->getE200Family() == PPC::E200_Z4 || "
                "Subtarget->getE200Family() == PPC::E200_Z7">,
      AssemblerPredicate<(any_of FeatureE200Z4Family, FeatureE200Z7Family)>;
// IVORs exist on every e200 except e200z0/e200z1 (fixed interrupt offsets).
def HasE200IVORs
    : Predicate<"Subtarget->isE200() && "
                "Subtarget->getE200Family() != PPC::E200_Z0 && "
                "Subtarget->getE200Family() != PPC::E200_Z1">,
      AssemblerPredicate<(all_of FeatureE200, (not FeatureE200Z0Family),
                              (not FeatureE200Z1Family))>;
// Registers absent from e200z0 only (timers/debug counter).
def IsE200NotZ0
    : Predicate<"Subtarget->isE200() && "
                "Subtarget->getE200Family() != PPC::E200_Z0">,
      AssemblerPredicate<(all_of FeatureE200, (not FeatureE200Z0Family))>;
// SPR 568 is ALTCTXCR on e200z1/e200z6 and IAC8 on e200z4/e200z7.
def IsE200Z1OrZ6
    : Predicate<"Subtarget->getE200Family() == PPC::E200_Z1 || "
                "Subtarget->getE200Family() == PPC::E200_Z6">,
      AssemblerPredicate<(any_of FeatureE200Z1Family, FeatureE200Z6Family)>;
// CTXCR (560): e200z1, e200z3, e200z6.
def HasE200CTXCR
    : Predicate<"Subtarget->getE200Family() == PPC::E200_Z1 || "
                "Subtarget->getE200Family() == PPC::E200_Z3 || "
                "Subtarget->getE200Family() == PPC::E200_Z6">,
      AssemblerPredicate<(any_of FeatureE200Z1Family, FeatureE200Z3Family,
                                 FeatureE200Z6Family)>;
// L1CSR0 (1010): e200z4, e200z6, e200z7.  L1FINV0 (1016): e200z6, e200z7.
def HasE200L1CSR0
    : Predicate<"Subtarget->getE200Family() == PPC::E200_Z4 || "
                "Subtarget->getE200Family() == PPC::E200_Z6 || "
                "Subtarget->getE200Family() == PPC::E200_Z7">,
      AssemblerPredicate<(any_of FeatureE200Z4Family, FeatureE200Z6Family,
                                 FeatureE200Z7Family)>;
def HasE200L1FINV0
    : Predicate<"Subtarget->getE200Family() == PPC::E200_Z6 || "
                "Subtarget->getE200Family() == PPC::E200_Z7">,
      AssemblerPredicate<(any_of FeatureE200Z6Family, FeatureE200Z7Family)>;
def IsE200Z7 : Predicate<"Subtarget->getE200Family() == PPC::E200_Z7">,
               AssemblerPredicate<(all_of FeatureE200Z7Family)>;

// mf<Name>/mt<Name> for SPR Num.  Read-only registers get no mt form.
multiclass E200SPR<string Name, int Num, Predicate P, bit ReadOnly = 0> {
  let Predicates = [P] in {
    def : InstAlias<"mf" # Name # " $Rx", (MFSPR gprc:$Rx, Num)>;
    if !not(ReadOnly) then
      def : InstAlias<"mt" # Name # " $Rx", (MTSPR Num, gprc:$Rx)>;
  }
}

// Registers common to all e200 cores.
defm : E200SPR<"csrr0", 58, IsE200>;
defm : E200SPR<"csrr1", 59, IsE200>;
defm : E200SPR<"ivpr", 63, IsE200>;
defm : E200SPR<"usprg0", 256, IsE200NotZ0>;
defm : E200SPR<"pir", 286, IsE200>;
defm : E200SPR<"dbsr", 304, IsE200>;
defm : E200SPR<"dbcr0", 308, IsE200>;
defm : E200SPR<"dbcr1", 309, IsE200>;
defm : E200SPR<"dbcr2", 310, IsE200>;
defm : E200SPR<"iac1", 312, IsE200>;
defm : E200SPR<"iac2", 313, IsE200>;
defm : E200SPR<"iac3", 314, IsE200>;
defm : E200SPR<"iac4", 315, IsE200>;
defm : E200SPR<"dac1", 316, IsE200>;
defm : E200SPR<"dac2", 317, IsE200>;
defm : E200SPR<"l1cfg0", 515, IsE200, 1>;
defm : E200SPR<"mcsr", 572, IsE200>;
defm : E200SPR<"dsrr0", 574, IsE200>;
defm : E200SPR<"dsrr1", 575, IsE200>;
defm : E200SPR<"hid0", 1008, IsE200>;
defm : E200SPR<"hid1", 1009, IsE200>;
defm : E200SPR<"bucsr", 1013, IsE200>;
defm : E200SPR<"mmucfg", 1015, IsE200, 1>;
defm : E200SPR<"svr", 1023, IsE200, 1>;

// Timer, debug-counter and MMU registers (not e200z0).
defm : E200SPR<"decar", 54, IsE200NotZ0>;
defm : E200SPR<"tsr", 336, IsE200NotZ0>;
defm : E200SPR<"dbcr3", 561, IsE200NotZ0>;
defm : E200SPR<"dbcnt", 562, IsE200NotZ0>;
defm : E200SPR<"mas0", 624, IsE200NotZ0>;
defm : E200SPR<"mas1", 625, IsE200NotZ0>;
defm : E200SPR<"mas2", 626, IsE200NotZ0>;
defm : E200SPR<"mas3", 627, IsE200NotZ0>;
defm : E200SPR<"mas4", 628, IsE200NotZ0>;
defm : E200SPR<"mas6", 630, IsE200NotZ0>;
defm : E200SPR<"tlb0cfg", 688, IsE200NotZ0, 1>;
defm : E200SPR<"tlb1cfg", 689, IsE200NotZ0, 1>;
defm : E200SPR<"mmucsr0", 1012, IsE200NotZ0>;

// Interrupt vector offset registers (not e200z0/e200z1).
foreach N = 0-15 in
  defm : E200SPR<"ivor" # N, !add(400, N), HasE200IVORs>;
foreach N = 32-34 in
  defm : E200SPR<"ivor" # N, !add(496, N), HasE200IVORs>;
defm : E200SPR<"ivor35", 531, IsE200Z7>;

// Context control registers.
defm : E200SPR<"ctxcr", 560, HasE200CTXCR>;
defm : E200SPR<"altctxcr", 568, IsE200Z1OrZ6>;

// e200z4/e200z7 debug, machine-check, cache and event registers.
defm : E200SPR<"dvc1", 318, IsE200Z4OrZ7>;
defm : E200SPR<"dvc2", 319, IsE200Z4OrZ7>;
defm : E200SPR<"l1cfg1", 516, IsE200Z4OrZ7, 1>;
defm : E200SPR<"dbcr4", 563, IsE200Z4OrZ7>;
defm : E200SPR<"dbcr5", 564, IsE200Z4OrZ7>;
defm : E200SPR<"iac5", 565, IsE200Z4OrZ7>;
defm : E200SPR<"iac6", 566, IsE200Z4OrZ7>;
defm : E200SPR<"iac7", 567, IsE200Z4OrZ7>;
defm : E200SPR<"iac8", 568, IsE200Z4OrZ7>;
defm : E200SPR<"dberc0", 569, IsE200Z4OrZ7>;
defm : E200SPR<"mcsrr0", 570, IsE200Z4OrZ7>;
defm : E200SPR<"mcsrr1", 571, IsE200Z4OrZ7>;
defm : E200SPR<"mcar", 573, IsE200Z4OrZ7>;
defm : E200SPR<"ddam", 576, IsE200Z4OrZ7>;
defm : E200SPR<"dbcr6", 603, IsE200Z4OrZ7>;
defm : E200SPR<"sprg8", 604, IsE200Z4OrZ7>;
defm : E200SPR<"sprg9", 605, IsE200Z4OrZ7>;
defm : E200SPR<"l1finv1", 959, IsE200Z4OrZ7>;
defm : E200SPR<"devent", 975, IsE200Z4OrZ7>;
defm : E200SPR<"l1csr1", 1011, IsE200Z4OrZ7>;

// Cache control registers.
defm : E200SPR<"l1csr0", 1010, HasE200L1CSR0>;
defm : E200SPR<"l1finv0", 1016, HasE200L1FINV0>;
