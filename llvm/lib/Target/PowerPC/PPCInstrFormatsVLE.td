//===-- PPCInstrFormatsVLE.td - PowerPC VLE instruction formats -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Instruction formats of the Variable-Length Encoding (VLE) category,
// VLEPEM Rev. 0 Appendix A.  The 32-bit X and XL forms used by VLE-only
// instructions are the EREF base formats.  Bit numbering is big-endian
// (Inst{0} is the most significant bit), as for all PowerPC formats.
//
//===----------------------------------------------------------------------===//

// Base class of the 16-bit VLE instructions.  The TSFlags layout matches
// class I.
class IVLE16<dag OOL, dag IOL, string asmstr, InstrItinClass itin>
    : Instruction {
  field bits<16> Inst;
  field bits<16> SoftFail = 0;
  let Size = 2;

  bit PPC64 = 0;
  let Namespace = "PPC";
  let OutOperandList = OOL;
  let InOperandList = IOL;
  let AsmString = asmstr;
  let Itinerary = itin;
  let DecoderNamespace = "VLE";

  bits<1> PPC970_First = 0;
  bits<1> PPC970_Single = 0;
  bits<1> PPC970_Cracked = 0;
  bits<3> PPC970_Unit = 0;
  let TSFlags{0}   = PPC970_First;
  let TSFlags{1}   = PPC970_Single;
  let TSFlags{2}   = PPC970_Cracked;
  let TSFlags{5...3} = PPC970_Unit;
  bits<1> XFormMemOp = 0;
  let TSFlags{6}  = XFormMemOp;
  bits<1> Prefixed = 0;
  let TSFlags{7}  = Prefixed;
  bits<1> SExt32To64 = 0;
  let TSFlags{8} = SExt32To64;
  bits<1> ZExt32To64 = 0;
  let TSFlags{9} = ZExt32To64;
  bits<1> MemriOp = 0;
  let TSFlags{10} = MemriOp;
  bits<1> VLE = 1;
  let TSFlags{11} = VLE;

  string BaseName = "";
  bit Interpretation64Bit = 0;
}

// Base class of the 32-bit VLE-specific instructions.
class IVLE32<bits<6> opcode, dag OOL, dag IOL, string asmstr,
             InstrItinClass itin>
    : I<opcode, OOL, IOL, asmstr, itin> {
  let VLE = 1;
  let DecoderNamespace = "VLE";
}

//===----------------------------------------------------------------------===//
// 16-bit forms
//===----------------------------------------------------------------------===//

// C form (A.3): the whole instruction is opcode.
class VLE_C<bits<16> opcode, string asmstr, InstrItinClass itin>
    : IVLE16<(outs), (ins), asmstr, itin> {
  let Inst{0...15} = opcode;
}

// R form (A.7): OPCD(0:5) XO(6:11) RX(12:15).
class VLE_R<bits<6> xo, dag OOL, dag IOL, string asmstr, InstrItinClass itin>
    : IVLE16<OOL, IOL, asmstr, itin> {
  bits<4> RX;
  let Inst{0...5} = 0;
  let Inst{6...11} = xo;
  let Inst{12...15} = RX;
}

// RR form (A.8): OPCD(0:5) XO(6:7) RY(8:11) RX(12:15).
class VLE_RR<bits<6> opcode, bits<2> xo, dag OOL, dag IOL, string asmstr,
             InstrItinClass itin>
    : IVLE16<OOL, IOL, asmstr, itin> {
  bits<4> RX;
  bits<4> RY;
  let Inst{0...5} = opcode;
  let Inst{6...7} = xo;
  let Inst{8...11} = RY;
  let Inst{12...15} = RX;
}

// IM5 form (A.4): OPCD(0:5) XO(6) UI5(7:11) RX(12:15).
class VLE_IM5<bits<6> opcode, bits<1> xo, dag OOL, dag IOL, string asmstr,
              InstrItinClass itin>
    : IVLE16<OOL, IOL, asmstr, itin> {
  bits<4> RX;
  bits<5> UI5;
  let Inst{0...5} = opcode;
  let Inst{6} = xo;
  let Inst{7...11} = UI5;
  let Inst{12...15} = RX;
}

// OIM5 form (A.5): OPCD(0:5) XO/Rc(6) OIM5(7:11) RX(12:15).  OIM5 holds the
// immediate minus one.
class VLE_OIM5<bits<6> opcode, bits<1> xo, dag OOL, dag IOL, string asmstr,
               InstrItinClass itin>
    : IVLE16<OOL, IOL, asmstr, itin> {
  bits<4> RX;
  bits<5> OIM5;
  let Inst{0...5} = opcode;
  let Inst{6} = xo;
  let Inst{7...11} = OIM5;
  let Inst{12...15} = RX;
}

// IM7 form (A.6): OPCD(0:4) UI7(5:11) RX(12:15).
class VLE_IM7<bits<5> opcode, dag OOL, dag IOL, string asmstr,
              InstrItinClass itin>
    : IVLE16<OOL, IOL, asmstr, itin> {
  bits<4> RX;
  bits<7> UI7;
  let Inst{0...4} = opcode;
  let Inst{5...11} = UI7;
  let Inst{12...15} = RX;
}

// SD4 form (A.9): OPCD(0:3) SD4(4:7) RZ(8:11) RX(12:15).
class VLE_SD4<bits<4> opcode, dag OOL, dag IOL, string asmstr,
              InstrItinClass itin>
    : IVLE16<OOL, IOL, asmstr, itin> {
  bits<4> RZ;
  bits<4> SD4;
  bits<4> RX;
  let Inst{0...3} = opcode;
  let Inst{4...7} = SD4;
  let Inst{8...11} = RZ;
  let Inst{12...15} = RX;
}

// BD8 form (A.2.2), se_b[l]: OPCD(0:5) XO(6) LK(7) BD8(8:15).
class VLE_BD8<bits<6> opcode, bit lk, dag OOL, dag IOL, string asmstr,
              InstrItinClass itin>
    : IVLE16<OOL, IOL, asmstr, itin> {
  bits<8> BD8;
  let Inst{0...5} = opcode;
  let Inst{6} = 0;
  let Inst{7} = lk;
  let Inst{8...15} = BD8;
}

// BD8 form (A.2.2), se_bc: OPCD(0:4) BO16(5) BI16(6:7) BD8(8:15).
class VLE_BD8C<bits<5> opcode, dag OOL, dag IOL, string asmstr,
               InstrItinClass itin>
    : IVLE16<OOL, IOL, asmstr, itin> {
  bits<1> BO16;
  bits<2> BI16;
  bits<8> BD8;
  let Inst{0...4} = opcode;
  let Inst{5} = BO16;
  let Inst{6...7} = BI16;
  let Inst{8...15} = BD8;
}

//===----------------------------------------------------------------------===//
// 32-bit forms
//===----------------------------------------------------------------------===//

// BD24 form (A.11): OPCD(0:5) 0(6) BD24(7:30) LK(31).
class VLE_BD24<bits<6> opcode, bit lk, dag OOL, dag IOL, string asmstr,
               InstrItinClass itin>
    : IVLE32<opcode, OOL, IOL, asmstr, itin> {
  bits<24> BD24;
  let Inst{6} = 0;
  let Inst{7...30} = BD24;
  let Inst{31} = lk;
}

// BD15 form (A.10): OPCD(0:9) BO32(10:11) BI32(12:15) BD15(16:30) LK(31).
class VLE_BD15<bits<10> opcode, bit lk, dag OOL, dag IOL, string asmstr,
               InstrItinClass itin>
    : IVLE32<opcode{9...4}, OOL, IOL, asmstr, itin> {
  bits<2> BO32;
  bits<4> BI32;
  bits<15> BD15;
  let Inst{6...9} = opcode{3...0};
  let Inst{10...11} = BO32;
  let Inst{12...15} = BI32;
  let Inst{16...30} = BD15;
  let Inst{31} = lk;
}

// BD15 form taking a "vlepred" operand as conditional branches in code
// generation do: BO32 is 0 (branch if false) or 1 (branch if true), taken from
// BO bit 1 (BIBO{3}) of the Book E predicate encoding, and BI32 is the CR field
// number concatenated with the bit within the field.
class VLE_BD15Pred<bit lk, dag OOL, dag IOL, string asmstr,
                   InstrItinClass itin>
    : IVLE32<30, OOL, IOL, asmstr, itin> {
  bits<7> BIBO;
  bits<3> CR;
  bits<15> BD15;
  let Inst{6...9} = 0b1000;
  let Inst{10} = 0;
  let Inst{11} = BIBO{3};
  let Inst{12...13} = CR{1...0};
  let Inst{14...15} = BIBO{6...5};
  let Inst{16...30} = BD15;
  let Inst{31} = lk;
}

// D8 form (A.12): OPCD(0:5) RT/RS(6:10) RA(11:15) XO(16:23) D8(24:31).
class VLE_D8<bits<6> opcode, bits<8> xo, dag OOL, dag IOL, string asmstr,
             InstrItinClass itin>
    : IVLE32<opcode, OOL, IOL, asmstr, itin> {
  bits<5> RST;
  bits<5> RA;
  bits<8> D8;
  let Inst{6...10} = RST;
  let Inst{11...15} = RA;
  let Inst{16...23} = xo;
  let Inst{24...31} = D8;
}

// SCI8 form (A.16): OPCD(0:5) RT/RS(6:10) RA(11:15) XO(16:19) Rc(20)
// F|SCL|UI8 (21:31).
class VLE_SCI8<bits<6> opcode, bits<4> xo, bit rc, dag OOL, dag IOL,
               string asmstr, InstrItinClass itin>
    : IVLE32<opcode, OOL, IOL, asmstr, itin> {
  bits<5> RST;
  bits<5> RA;
  bits<11> SCI8;
  let Inst{6...10} = RST;
  let Inst{11...15} = RA;
  let Inst{16...19} = xo;
  let Inst{20} = rc;
  let Inst{21...31} = SCI8;
}

// SCI8 compare form (A.16): OPCD(0:5) 00 L(8) BF32(9:10) RA(11:15)
// XO(16:20) F|SCL|UI8 (21:31).
class VLE_SCI8C<bits<6> opcode, bit l, bits<5> xo, dag OOL, dag IOL,
                string asmstr, InstrItinClass itin>
    : IVLE32<opcode, OOL, IOL, asmstr, itin> {
  bits<2> BF32;
  bits<5> RA;
  bits<11> SCI8;
  let Inst{6...7} = 0;
  let Inst{8} = l;
  let Inst{9...10} = BF32;
  let Inst{11...15} = RA;
  let Inst{16...20} = xo;
  let Inst{21...31} = SCI8;
}

// I16A form (A.13): OPCD(0:5) imm(0:4)(6:10) RA(11:15) XO(16:20)
// imm(5:15)(21:31).
class VLE_I16A<bits<6> opcode, bits<5> xo, dag OOL, dag IOL, string asmstr,
               InstrItinClass itin>
    : IVLE32<opcode, OOL, IOL, asmstr, itin> {
  bits<5> RA;
  bits<16> I16;
  let Inst{6...10} = I16{15...11};
  let Inst{11...15} = RA;
  let Inst{16...20} = xo;
  let Inst{21...31} = I16{10...0};
}

// I16L form (A.14): OPCD(0:5) RT(6:10) imm(0:4)(11:15) XO(16:20)
// imm(5:15)(21:31).
class VLE_I16L<bits<6> opcode, bits<5> xo, dag OOL, dag IOL, string asmstr,
               InstrItinClass itin>
    : IVLE32<opcode, OOL, IOL, asmstr, itin> {
  bits<5> RT;
  bits<16> I16;
  let Inst{6...10} = RT;
  let Inst{11...15} = I16{15...11};
  let Inst{16...20} = xo;
  let Inst{21...31} = I16{10...0};
}

// LI20 form (A.17): OPCD(0:5) RT(6:10) li20(4:8)(11:15) 0(16)
// li20(0:3)(17:20) li20(9:19)(21:31).
class VLE_LI20<bits<6> opcode, dag OOL, dag IOL, string asmstr,
               InstrItinClass itin>
    : IVLE32<opcode, OOL, IOL, asmstr, itin> {
  bits<5> RT;
  bits<20> LI20;
  let Inst{6...10} = RT;
  let Inst{11...15} = LI20{15...11};
  let Inst{16} = 0;
  let Inst{17...20} = LI20{19...16};
  let Inst{21...31} = LI20{10...0};
}

// M form (A.15): OPCD(0:5) RS(6:10) RA(11:15) SH(16:20) MB(21:25) ME(26:30)
// XO(31).
class VLE_M<bits<6> opcode, bit xo, dag OOL, dag IOL, string asmstr,
            InstrItinClass itin>
    : IVLE32<opcode, OOL, IOL, asmstr, itin> {
  bits<5> RS;
  bits<5> RA;
  bits<5> SH;
  bits<5> MB;
  bits<5> ME;
  let Inst{6...10} = RS;
  let Inst{11...15} = RA;
  let Inst{16...20} = SH;
  let Inst{21...25} = MB;
  let Inst{26...30} = ME;
  let Inst{31} = xo;
}

// X form with RS(6:10) RA(11:15) RB(16:20) XO(21:30) Rc(31) (e_rlw).
class VLE_X<bits<10> xo, bit rc, dag OOL, dag IOL, string asmstr,
            InstrItinClass itin>
    : IVLE32<31, OOL, IOL, asmstr, itin> {
  bits<5> RS;
  bits<5> RA;
  bits<5> RB;
  let Inst{6...10} = RS;
  let Inst{11...15} = RA;
  let Inst{16...20} = RB;
  let Inst{21...30} = xo;
  let Inst{31} = rc;
}

// X form with RS(6:10) RA(11:15) SH(16:20) XO(21:30) Rc(31) (e_rlwi,
// e_slwi, e_srwi).
class VLE_XSH<bits<10> xo, bit rc, dag OOL, dag IOL, string asmstr,
              InstrItinClass itin>
    : IVLE32<31, OOL, IOL, asmstr, itin> {
  bits<5> RS;
  bits<5> RA;
  bits<5> SH;
  let Inst{6...10} = RS;
  let Inst{11...15} = RA;
  let Inst{16...20} = SH;
  let Inst{21...30} = xo;
  let Inst{31} = rc;
}

// X form compare: crD(6:8) 0(9:10) RA(11:15) RB(16:20) XO(21:30) 0(31)
// (e_cmph, e_cmphl).
class VLE_XC<bits<10> xo, dag OOL, dag IOL, string asmstr, InstrItinClass itin>
    : IVLE32<31, OOL, IOL, asmstr, itin> {
  bits<3> BF;
  bits<5> RA;
  bits<5> RB;
  let Inst{6...8} = BF;
  let Inst{9...10} = 0;
  let Inst{11...15} = RA;
  let Inst{16...20} = RB;
  let Inst{21...30} = xo;
  let Inst{31} = 0;
}

// XL form CR logical: crbD(6:10) crbA(11:15) crbB(16:20) XO(21:30).
class VLE_XL<bits<10> xo, dag OOL, dag IOL, string asmstr, InstrItinClass itin>
    : IVLE32<31, OOL, IOL, asmstr, itin> {
  bits<5> CRD;
  bits<5> CRA;
  bits<5> CRB;
  let Inst{6...10} = CRD;
  let Inst{11...15} = CRA;
  let Inst{16...20} = CRB;
  let Inst{21...30} = xo;
  let Inst{31} = 0;
}

// XL form e_mcrf: crD(6:8) crS(11:13) XO(21:30).
class VLE_XLMCRF<bits<10> xo, dag OOL, dag IOL, string asmstr,
                 InstrItinClass itin>
    : IVLE32<31, OOL, IOL, asmstr, itin> {
  bits<3> BF;
  bits<3> BFA;
  let Inst{6...8} = BF;
  let Inst{9...10} = 0;
  let Inst{11...13} = BFA;
  let Inst{14...20} = 0;
  let Inst{21...30} = xo;
  let Inst{31} = 0;
}
