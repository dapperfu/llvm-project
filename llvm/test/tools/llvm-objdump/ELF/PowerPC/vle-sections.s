# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -filetype=obj %s -o %t.o
# RUN: llvm-objdump -d %t.o | FileCheck %s
# RUN: llvm-objdump -d --mattr=-spe-isa %t.o | FileCheck --check-prefix=NOSPE %s

## Sections with SHF_PPC_VLE are disassembled as VLE code and the others as
## Book E (VLEPIM Rev. 1 §2.2.2).  The SPE category comes from the
## .PPC.EMB.apuinfo note (EFS APU), so efsadd decodes without --mcpu.

# CHECK:      Disassembly of section .text:
# CHECK:      <booke>:
# CHECK-NEXT:   0: 7c 64 2a 14  add 3, 4, 5
# CHECK-NEXT:   4: 7c 64 28 9e  iseleq 3, 4, 5
# CHECK:      Disassembly of section .text.vle:
# CHECK:      <vle>:
# CHECK-NEXT:   0: 04 43        se_add 3, 4
# CHECK-NEXT:   2: 79 ff ff ff  e_bl 0x0 <vle>
# CHECK-NEXT:   6: 10 64 2a c0  efsadd 3, 4, 5
# CHECK-NEXT:   a: 7a 16 ff f6  e_beq 1, 0x0 <vle>
# CHECK-NEXT:   e: 00 04        se_blr

# NOSPE:   6: 10 64 2a c0  <unknown>

	.text
booke:
	add 3, 4, 5
	isel 3, 4, 5, 2

	.section .text.vle,"axv"
vle:
	se_add 3, 4
	e_bl vle
	efsadd 3, 4, 5
	e_beq 1, vle
	se_blr
