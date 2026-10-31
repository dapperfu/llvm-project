//===-- PPCInstrVLE.td - PowerPC VLE instructions ----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The Variable-Length Encoding (VLE) instruction category: VLEPEM Rev. 0
// Chapter 3 and Table B-2, simplified mnemonics from VLEPIM Rev. 1
// Appendix A.  Shared Book E instructions keep their Book E definitions;
// PPCInstrVLEShared.td lists which of them are valid in VLE mode.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Operands
//===----------------------------------------------------------------------===//

def OImm5 : ImmediateAsmOperand<"isOImm5">;
def SCI8Imm : ImmediateAsmOperand<"isSCI8Imm">;
def NegSCI8Imm : ImmediateAsmOperand<"isNegSCI8Imm", "addNegImmOperands">;
def S16U16Imm : ImmediateAsmOperand<"isS16U16Imm", "addS16ImmOperands">;
def NegS16U16Imm : ImmediateAsmOperand<"isNegS16U16Imm", "addNegImmOperands">;
def NegS16Imm : ImmediateAsmOperand<"isNegS16Imm", "addNegImmOperands">;
def S20Imm : ImmediateAsmOperand<"isS20Imm">;
def SD4ImmX1 : ImmediateAsmOperand<"isSD4Imm<1>">;
def SD4ImmX2 : ImmediateAsmOperand<"isSD4Imm<2>">;
def SD4ImmX4 : ImmediateAsmOperand<"isSD4Imm<4>">;
def DispD8Imm : ImmediateAsmOperand<"isSImm<8>">;

// OIM5: 1..32 encoded as 0..31.
def oimm5 : Operand<i32> {
  let PrintMethod = "printUImmOperand<6>";
  let EncoderMethod = "getOImm5Encoding";
  let DecoderMethod = "decodeOImm5Operand";
  let ParserMatchClass = OImm5;
  let OperandType = "OPERAND_IMMEDIATE";
}

// SCI8: a 32-bit value synthesized from F, SCL and UI8 (VLEPEM Rev. 0
// Table A-1).
class SCI8Operand<AsmOperandClass AsmOp> : Operand<i32> {
  let PrintMethod = "printSImmOperand<32>";
  let EncoderMethod = "getSCI8Encoding";
  let DecoderMethod = "decodeSCI8Operand";
  let ParserMatchClass = AsmOp;
  let OperandType = "OPERAND_IMMEDIATE";
}
def sci8imm : SCI8Operand<SCI8Imm>;
def neg_sci8imm : SCI8Operand<NegSCI8Imm>;

// 16-bit immediates split across the I16A (D relocations) and I16L
// (A relocations) fields.
def vle_s16imm_d
    : ImmediateRelocOp<i32, "S16U16Imm", 16, "PPC::fixup_ppc_vle_split16d"> {
  let PrintMethod = "printS16ImmOperand";
}
def vle_neg_s16imm_d
    : ImmediateRelocOp<i32, "NegS16U16Imm", 16, "PPC::fixup_ppc_vle_split16d"> {
  let PrintMethod = "printS16ImmOperand";
}
def vle_u16imm_d
    : UImmediateRelocOp<i32, "U16Imm", 16, "PPC::fixup_ppc_vle_split16d">;
def vle_u16imm_a
    : UImmediateRelocOp<i32, "U16Imm", 16, "PPC::fixup_ppc_vle_split16a">;

// e_add16i accepts @sda21, which relocates the whole instruction.
def vle_add16imm
    : ImmediateRelocOp<i32, "S16Imm", 16, "PPC::fixup_ppc_half16"> {
  let EncoderMethod = "getVLEAdd16IEncoding";
}
def vle_neg_s16imm
    : ImmediateRelocOp<i32, "NegS16Imm", 16, "PPC::fixup_ppc_half16"> {
  let PrintMethod = "printS16ImmOperand";
}

// LI20: only @sda21 can relocate it (VLEPIM Rev. 1 Table 2-4).
def vle_li20imm : Operand<i32> {
  let PrintMethod = "printVLELI20Operand";
  let EncoderMethod = "getVLELI20Encoding";
  let DecoderMethod = "decodeSImmOperand<20>";
  let ParserMatchClass = S20Imm;
  let OperandType = "OPERAND_IMMEDIATE";
}

// D8 displacement: signed 8 bits, no relocation.
def dispD8 : Operand<iPTR> {
  let ParserMatchClass = DispD8Imm;
  let DecoderMethod = "decodeSImmOperand<8>";
}
def memd8 : Operand<iPTR> {
  let PrintMethod = "printMemRegImm";
  let MIOperandInfo = (ops dispD8:$imm, ptr_rc_nor0:$reg);
  let OperandType = "OPERAND_MEMORY";
}

// SD4 displacement: unsigned 4 bits scaled by the access size.
class DispSD4<int Scale> : Operand<iPTR> {
  let ParserMatchClass = !cast<AsmOperandClass>("SD4ImmX" # Scale);
  let EncoderMethod = "getDispSD4Encoding<" # !logtwo(Scale) # ">";
  let DecoderMethod = "decodeDispSD4Operand<" # !logtwo(Scale) # ">";
}
def dispSD4X1 : DispSD4<1>;
def dispSD4X2 : DispSD4<2>;
def dispSD4X4 : DispSD4<4>;
class MemSD4<Operand Disp> : Operand<iPTR> {
  let PrintMethod = "printMemRegImm";
  let MIOperandInfo = (ops Disp:$imm, gprvle16:$reg);
  let OperandType = "OPERAND_MEMORY";
}
def memsd4b : MemSD4<dispSD4X1>;
def memsd4h : MemSD4<dispSD4X2>;
def memsd4w : MemSD4<dispSD4X4>;

// Branch targets: halfword displacements of 8, 15 and 24 bits.
class VLEBrAsmOperand<int Bits> : AsmOperandClass {
  let Name = "VLEBr" # Bits;
  let PredicateMethod = "isVLEBr<" # Bits # ">";
  let RenderMethod = "addVLEBranchTargetOperands";
}
def PPCVLEBr8AsmOperand : VLEBrAsmOperand<8>;
def PPCVLEBr15AsmOperand : VLEBrAsmOperand<15>;
def PPCVLEBr24AsmOperand : VLEBrAsmOperand<24>;
class VLEBrTarget<ValueType VT, int Bits, string Fixup> : Operand<VT> {
  let PrintMethod = "printVLEBranchOperand";
  let EncoderMethod = "getVLEBrEncoding<" # Fixup # ">";
  let DecoderMethod = "decodeVLEBrTarget<" # Bits # ">";
  let ParserMatchClass = !cast<AsmOperandClass>("PPCVLEBr" # Bits # "AsmOperand");
  let OperandType = "OPERAND_PCREL";
}
def vlebrtarget8 : VLEBrTarget<OtherVT, 8, "PPC::fixup_ppc_vle_rel8">;
def vlebrtarget15 : VLEBrTarget<OtherVT, 15, "PPC::fixup_ppc_vle_rel15">;
def vlebrtarget24 : VLEBrTarget<OtherVT, 24, "PPC::fixup_ppc_vle_rel24">;
def vlecalltarget8 : VLEBrTarget<iPTR, 8, "PPC::fixup_ppc_vle_rel8">;
def vlecalltarget24 : VLEBrTarget<iPTR, 24, "PPC::fixup_ppc_vle_rel24">;

// Assembler-only pseudo instructions expanded into VLE instructions.
class VLEAsmPseudo<string asm, dag iops> : PPCAsmPseudo<asm, iops> {
  let TSFlags{11} = 1;
}

let Predicates = [IsVLE] in {

//===----------------------------------------------------------------------===//
// BD8, BD15, BD24 and C-form branches (VLEPEM Rev. 0 §2.3.2)
//===----------------------------------------------------------------------===//

let isBranch = 1, isTerminator = 1, hasCtrlDep = 1 in {
  let isBarrier = 1 in {
    def E_B : VLE_BD24<30, 0, (outs), (ins vlebrtarget24:$BD24),
                       "e_b $BD24", IIC_BrB>;
    def SE_B : VLE_BD8<0b111010, 0, (outs), (ins vlebrtarget8:$BD8),
                       "se_b $BD8", IIC_BrB>;
  }
  let Uses = [CTR], Defs = [CTR] in
  def E_BC : VLE_BD15<0b0111101000, 0, (outs),
                      (ins u2imm:$BO32, crbitrc_vle:$BI32,
                           vlebrtarget15:$BD15),
                      "e_bc $BO32, $BI32, $BD15", IIC_BrB>;
  def SE_BC : VLE_BD8C<0b11100, (outs),
                       (ins u1imm:$BO16, crbitrc_cr0:$BI16, vlebrtarget8:$BD8),
                       "se_bc $BO16, $BI16, $BD8", IIC_BrB>;
  let isCodeGenOnly = 1 in
  def E_BCC : VLE_BD15Pred<0, (outs),
                           (ins (vlepred $BIBO, $CR):$cond,
                                vlebrtarget15:$BD15),
                           "e_b${cond:cc} ${cond:reg}, $BD15", IIC_BrB>;
  let isReturn = 1, isBarrier = 1, Uses = [LR] in
  def SE_BLR : VLE_C<0x0004, "se_blr", IIC_BrB>;
  let isIndirectBranch = 1, isBarrier = 1, Uses = [CTR] in
  def SE_BCTR : VLE_C<0x0006, "se_bctr", IIC_BrB>;
}

let isCall = 1, Defs = [LR] in {
  def E_BL : VLE_BD24<30, 1, (outs), (ins vlecalltarget24:$BD24),
                      "e_bl $BD24", IIC_BrB>;
  def SE_BL : VLE_BD8<0b111010, 1, (outs), (ins vlecalltarget8:$BD8),
                      "se_bl $BD8", IIC_BrB>;
  let Uses = [CTR], Defs = [LR, CTR] in
  def E_BCL : VLE_BD15<0b0111101000, 1, (outs),
                       (ins u2imm:$BO32, crbitrc_vle:$BI32,
                            vlebrtarget15:$BD15),
                       "e_bcl $BO32, $BI32, $BD15", IIC_BrB>;
  let isCodeGenOnly = 1 in
  def E_BCCL : VLE_BD15Pred<1, (outs),
                            (ins (vlepred $BIBO, $CR):$cond,
                                 vlebrtarget15:$BD15),
                            "e_b${cond:cc}l ${cond:reg}, $BD15", IIC_BrB>;
  let Uses = [LR] in
  def SE_BLRL : VLE_C<0x0005, "se_blrl", IIC_BrB>;
  let Uses = [CTR] in
  def SE_BCTRL : VLE_C<0x0007, "se_bctrl", IIC_BrB>;
}

// Branch simplified mnemonics (VLEPIM Rev. 1 Table A-23).
def : InstAlias<"e_bdnz $dst", (E_BC 2, CR0LT, vlebrtarget15:$dst)>;
def : InstAlias<"e_bdz $dst", (E_BC 3, CR0LT, vlebrtarget15:$dst)>;
def : InstAlias<"e_bdnzl $dst", (E_BCL 2, CR0LT, vlebrtarget15:$dst)>;
def : InstAlias<"e_bdzl $dst", (E_BCL 3, CR0LT, vlebrtarget15:$dst)>;
def : InstAlias<"e_bt $bi, $dst",
                (E_BC 1, crbitrc_vle:$bi, vlebrtarget15:$dst), 0>;
def : InstAlias<"e_bf $bi, $dst",
                (E_BC 0, crbitrc_vle:$bi, vlebrtarget15:$dst), 0>;
def : InstAlias<"e_btl $bi, $dst",
                (E_BCL 1, crbitrc_vle:$bi, vlebrtarget15:$dst), 0>;
def : InstAlias<"e_bfl $bi, $dst",
                (E_BCL 0, crbitrc_vle:$bi, vlebrtarget15:$dst), 0>;
def : InstAlias<"se_bt $bi, $dst",
                (SE_BC 1, crbitrc_cr0:$bi, vlebrtarget8:$dst), 0>;
def : InstAlias<"se_bf $bi, $dst",
                (SE_BC 0, crbitrc_cr0:$bi, vlebrtarget8:$dst), 0>;

// e_b<cond>[l] [crS,] target and se_b<cond> target.  BO is 1 to branch if
// the CR0 bit is set and 0 to branch if it is clear; BIBO is the Book E
// predicate code used with an explicit CR field.  Priority is 0 for the
// synonyms that should not be printed.
multiclass VLEBranchCond<string cond, bit bo, Register bi, int bibo,
                         int Priority> {
  def : InstAlias<"e_b" # cond # " $dst",
                  (E_BC bo, bi, vlebrtarget15:$dst), Priority>;
  def : InstAlias<"e_b" # cond # "l $dst",
                  (E_BCL bo, bi, vlebrtarget15:$dst), Priority>;
  def : InstAlias<"e_b" # cond # " $cr, $dst",
                  (E_BCC (vlepred bibo, crrc_vle:$cr), vlebrtarget15:$dst), 0>;
  def : InstAlias<"e_b" # cond # "l $cr, $dst",
                  (E_BCCL (vlepred bibo, crrc_vle:$cr), vlebrtarget15:$dst), 0>;
  def : InstAlias<"se_b" # cond # " $dst",
                  (SE_BC bo, bi, vlebrtarget8:$dst), Priority>;
}
defm : VLEBranchCond<"lt", 1, CR0LT, 12, 1>;
defm : VLEBranchCond<"gt", 1, CR0GT, 44, 1>;
defm : VLEBranchCond<"eq", 1, CR0EQ, 76, 1>;
defm : VLEBranchCond<"so", 1, CR0UN, 108, 1>;
defm : VLEBranchCond<"un", 1, CR0UN, 108, 0>;
defm : VLEBranchCond<"ge", 0, CR0LT, 4, 1>;
defm : VLEBranchCond<"nl", 0, CR0LT, 4, 0>;
defm : VLEBranchCond<"le", 0, CR0GT, 36, 1>;
defm : VLEBranchCond<"ng", 0, CR0GT, 36, 0>;
defm : VLEBranchCond<"ne", 0, CR0EQ, 68, 1>;
defm : VLEBranchCond<"ns", 0, CR0UN, 100, 1>;
defm : VLEBranchCond<"nu", 0, CR0UN, 100, 0>;

//===----------------------------------------------------------------------===//
// C form: system linkage and synchronization (VLEPEM Rev. 0 §2.3.3, §2.5.1)
//===----------------------------------------------------------------------===//

let hasSideEffects = 1 in {
  let isTrap = 1 in
  def SE_ILLEGAL : VLE_C<0x0000, "se_illegal", IIC_IntTrapW>;
  def SE_ISYNC : VLE_C<0x0001, "se_isync", IIC_SprISYNC>;
  def SE_SC : VLE_C<0x0002, "se_sc", IIC_SprSC>;
  let isReturn = 1, isTerminator = 1, isBarrier = 1 in {
    def SE_RFI : VLE_C<0x0008, "se_rfi", IIC_SprRFI>;
    def SE_RFCI : VLE_C<0x0009, "se_rfci", IIC_SprRFI>;
    let Predicates = [IsVLE, HasRFDI] in
    def SE_RFDI : VLE_C<0x000A, "se_rfdi", IIC_SprRFI>;
    let Predicates = [IsVLE, HasRFMCI] in
    def SE_RFMCI : VLE_C<0x000B, "se_rfmci", IIC_SprRFI>;
  }
}

//===----------------------------------------------------------------------===//
// R form (VLEPEM Rev. 0 Table A-1, Figure A-6)
//===----------------------------------------------------------------------===//

class VLE_R_Tied<bits<6> xo, string asmstr, InstrItinClass itin>
    : VLE_R<xo, (outs gprvle16:$RX), (ins gprvle16:$RXi), asmstr, itin>,
      RegConstraint<"$RXi = $RX">;

def SE_NOT : VLE_R_Tied<2, "se_not $RX", IIC_IntSimple>;
def SE_NEG : VLE_R_Tied<3, "se_neg $RX", IIC_IntSimple>;
def SE_EXTZB : VLE_R_Tied<12, "se_extzb $RX", IIC_IntSimple>;
def SE_EXTSB : VLE_R_Tied<13, "se_extsb $RX", IIC_IntSimple>;
def SE_EXTZH : VLE_R_Tied<14, "se_extzh $RX", IIC_IntSimple>;
def SE_EXTSH : VLE_R_Tied<15, "se_extsh $RX", IIC_IntSimple>;

let Uses = [LR] in
def SE_MFLR : VLE_R<8, (outs gprvle16:$RX), (ins), "se_mflr $RX",
                    IIC_SprMFSPR>;
let Defs = [LR] in
def SE_MTLR : VLE_R<9, (outs), (ins gprvle16:$RX), "se_mtlr $RX",
                    IIC_SprMTSPR>;
let Uses = [CTR] in
def SE_MFCTR : VLE_R<10, (outs gprvle16:$RX), (ins), "se_mfctr $RX",
                     IIC_SprMFSPR>;
let Defs = [CTR] in
def SE_MTCTR : VLE_R<11, (outs), (ins gprvle16:$RX), "se_mtctr $RX",
                     IIC_SprMTSPR>;

//===----------------------------------------------------------------------===//
// RR form (VLEPEM Rev. 0 Table A-1, Figure A-7)
//===----------------------------------------------------------------------===//

class VLE_RR_Tied<bits<6> opcode, bits<2> xo, string asmstr,
                  InstrItinClass itin>
    : VLE_RR<opcode, xo, (outs gprvle16:$RX),
             (ins gprvle16:$RXi, gprvle16:$RY), asmstr, itin>,
      RegConstraint<"$RXi = $RX">;
class VLE_RR_Cmp<bits<2> xo, string asmstr>
    : VLE_RR<0b000011, xo, (outs), (ins gprvle16:$RX, gprvle16:$RY), asmstr,
             IIC_IntCompare> {
  let Defs = [CR0];
}

def SE_MR : VLE_RR<0b000000, 0b01, (outs gprvle16:$RX), (ins gprvle16:$RY),
                   "se_mr $RX, $RY", IIC_IntSimple>;
def SE_MTAR : VLE_RR<0b000000, 0b10, (outs gprvlealt:$RX), (ins gprvle16:$RY),
                     "se_mtar $RX, $RY", IIC_IntSimple>;
def SE_MFAR : VLE_RR<0b000000, 0b11, (outs gprvle16:$RX), (ins gprvlealt:$RY),
                     "se_mfar $RX, $RY", IIC_IntSimple>;
def SE_ADD : VLE_RR_Tied<0b000001, 0b00, "se_add $RX, $RY", IIC_IntSimple>;
def SE_MULLW : VLE_RR_Tied<0b000001, 0b01, "se_mullw $RX, $RY",
                           IIC_IntMulHW>;
def SE_SUB : VLE_RR_Tied<0b000001, 0b10, "se_sub $RX, $RY", IIC_IntSimple>;
def SE_SUBF : VLE_RR_Tied<0b000001, 0b11, "se_subf $RX, $RY", IIC_IntSimple>;
def SE_CMP : VLE_RR_Cmp<0b00, "se_cmp $RX, $RY">;
def SE_CMPL : VLE_RR_Cmp<0b01, "se_cmpl $RX, $RY">;
def SE_CMPH : VLE_RR_Cmp<0b10, "se_cmph $RX, $RY">;
def SE_CMPHL : VLE_RR_Cmp<0b11, "se_cmphl $RX, $RY">;
def SE_SRW : VLE_RR_Tied<0b010000, 0b00, "se_srw $RX, $RY", IIC_IntGeneral>;
let Defs = [CARRY] in
def SE_SRAW : VLE_RR_Tied<0b010000, 0b01, "se_sraw $RX, $RY", IIC_IntShift>;
def SE_SLW : VLE_RR_Tied<0b010000, 0b10, "se_slw $RX, $RY", IIC_IntGeneral>;
def SE_OR : VLE_RR_Tied<0b010001, 0b00, "se_or $RX, $RY", IIC_IntSimple>;
def SE_ANDC : VLE_RR_Tied<0b010001, 0b01, "se_andc $RX, $RY", IIC_IntSimple>;
def SE_AND : VLE_RR_Tied<0b010001, 0b10, "se_and $RX, $RY", IIC_IntSimple>;
let Defs = [CR0] in
def SE_AND_rec : VLE_RR_Tied<0b010001, 0b11, "se_and. $RX, $RY",
                             IIC_IntSimple>;

//===----------------------------------------------------------------------===//
// IM5, OIM5 and IM7 forms (VLEPEM Rev. 0 Figures A-3 to A-5)
//===----------------------------------------------------------------------===//

class VLE_IM5_Tied<bits<6> opcode, bits<1> xo, string asmstr,
                   InstrItinClass itin>
    : VLE_IM5<opcode, xo, (outs gprvle16:$RX),
              (ins gprvle16:$RXi, u5imm:$UI5), asmstr, itin>,
      RegConstraint<"$RXi = $RX">;
class VLE_OIM5_Tied<bits<6> opcode, bits<1> xo, string asmstr>
    : VLE_OIM5<opcode, xo, (outs gprvle16:$RX),
               (ins gprvle16:$RXi, oimm5:$OIM5), asmstr, IIC_IntSimple>,
      RegConstraint<"$RXi = $RX">;

def SE_ADDI : VLE_OIM5_Tied<0b001000, 0, "se_addi $RX, $OIM5">;
let Defs = [CR0] in
def SE_CMPLI : VLE_OIM5<0b001000, 1, (outs), (ins gprvle16:$RX, oimm5:$OIM5),
                        "se_cmpli $RX, $OIM5", IIC_IntCompare>;
def SE_SUBI : VLE_OIM5_Tied<0b001001, 0, "se_subi $RX, $OIM5">;
let Defs = [CR0] in
def SE_SUBI_rec : VLE_OIM5_Tied<0b001001, 1, "se_subi. $RX, $OIM5">;
let Defs = [CR0] in {
  def SE_CMPI : VLE_IM5<0b001010, 1, (outs), (ins gprvle16:$RX, u5imm:$UI5),
                        "se_cmpi $RX, $UI5", IIC_IntCompare>;
  def SE_BTSTI : VLE_IM5<0b011001, 1, (outs), (ins gprvle16:$RX, u5imm:$UI5),
                         "se_btsti $RX, $UI5", IIC_IntCompare>;
}
def SE_BMASKI : VLE_IM5<0b001011, 0, (outs gprvle16:$RX), (ins u5imm:$UI5),
                        "se_bmaski $RX, $UI5", IIC_IntSimple>;
def SE_ANDI : VLE_IM5_Tied<0b001011, 1, "se_andi $RX, $UI5", IIC_IntSimple>;
def SE_BCLRI : VLE_IM5_Tied<0b011000, 0, "se_bclri $RX, $UI5", IIC_IntSimple>;
def SE_BGENI : VLE_IM5<0b011000, 1, (outs gprvle16:$RX), (ins u5imm:$UI5),
                       "se_bgeni $RX, $UI5", IIC_IntSimple>;
def SE_BSETI : VLE_IM5_Tied<0b011001, 0, "se_bseti $RX, $UI5", IIC_IntSimple>;
def SE_SRWI : VLE_IM5_Tied<0b011010, 0, "se_srwi $RX, $UI5", IIC_IntShift>;
let Defs = [CARRY] in
def SE_SRAWI : VLE_IM5_Tied<0b011010, 1, "se_srawi $RX, $UI5", IIC_IntShift>;
def SE_SLWI : VLE_IM5_Tied<0b011011, 0, "se_slwi $RX, $UI5", IIC_IntShift>;

def SE_LI : VLE_IM7<0b01001, (outs gprvle16:$RX), (ins u7imm:$UI7),
                    "se_li $RX, $UI7", IIC_IntSimple>;

//===----------------------------------------------------------------------===//
// SD4 form loads and stores (VLEPEM Rev. 0 Figure A-8)
//===----------------------------------------------------------------------===//

let mayLoad = 1 in {
  def SE_LBZ : VLE_SD4<0b1000, (outs gprvle16:$RZ),
                       (ins (memsd4b $SD4, $RX):$addr), "se_lbz $RZ, $addr",
                       IIC_LdStLoad>, MemriOp;
  def SE_LHZ : VLE_SD4<0b1010, (outs gprvle16:$RZ),
                       (ins (memsd4h $SD4, $RX):$addr), "se_lhz $RZ, $addr",
                       IIC_LdStLoad>, MemriOp;
  def SE_LWZ : VLE_SD4<0b1100, (outs gprvle16:$RZ),
                       (ins (memsd4w $SD4, $RX):$addr), "se_lwz $RZ, $addr",
                       IIC_LdStLoad>, MemriOp;
}
let mayStore = 1 in {
  def SE_STB : VLE_SD4<0b1001, (outs),
                       (ins gprvle16:$RZ, (memsd4b $SD4, $RX):$addr),
                       "se_stb $RZ, $addr", IIC_LdStStore>, MemriOp;
  def SE_STH : VLE_SD4<0b1011, (outs),
                       (ins gprvle16:$RZ, (memsd4h $SD4, $RX):$addr),
                       "se_sth $RZ, $addr", IIC_LdStStore>, MemriOp;
  def SE_STW : VLE_SD4<0b1101, (outs),
                       (ins gprvle16:$RZ, (memsd4w $SD4, $RX):$addr),
                       "se_stw $RZ, $addr", IIC_LdStStore>, MemriOp;
}

//===----------------------------------------------------------------------===//
// D form (VLEPEM Rev. 0 Chapter 3; EREF D form)
//===----------------------------------------------------------------------===//

let VLE = 1, DecoderNamespace = "VLE" in {
  def E_ADD16I : DForm_2<7, (outs gprc:$RST), (ins gprc:$RA, vle_add16imm:$D),
                         "e_add16i $RST, $RA, $D", IIC_IntSimple, []>;
  let mayLoad = 1 in {
    def E_LBZ : DForm_1<12, (outs gprc:$RST), (ins (memri $D, $RA):$addr),
                        "e_lbz $RST, $addr", IIC_LdStLoad, []>;
    def E_LHA : DForm_1<14, (outs gprc:$RST), (ins (memri $D, $RA):$addr),
                        "e_lha $RST, $addr", IIC_LdStLHA, []>;
    def E_LWZ : DForm_1<20, (outs gprc:$RST), (ins (memri $D, $RA):$addr),
                        "e_lwz $RST, $addr", IIC_LdStLoad, []>;
    def E_LHZ : DForm_1<22, (outs gprc:$RST), (ins (memri $D, $RA):$addr),
                        "e_lhz $RST, $addr", IIC_LdStLoad, []>;
  }
  let mayStore = 1 in {
    def E_STB : DForm_1<13, (outs), (ins gprc:$RST, (memri $D, $RA):$addr),
                        "e_stb $RST, $addr", IIC_LdStStore, []>;
    def E_STW : DForm_1<21, (outs), (ins gprc:$RST, (memri $D, $RA):$addr),
                        "e_stw $RST, $addr", IIC_LdStStore, []>;
    def E_STH : DForm_1<23, (outs), (ins gprc:$RST, (memri $D, $RA):$addr),
                        "e_sth $RST, $addr", IIC_LdStStore, []>;
  }
}

} // Predicates = [IsVLE]
