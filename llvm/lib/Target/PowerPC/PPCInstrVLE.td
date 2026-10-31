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
