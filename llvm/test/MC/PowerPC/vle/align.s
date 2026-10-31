# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -mattr=+vle -filetype=obj %s -o - \
# RUN:   | llvm-objdump -s -j .text - | FileCheck %s

# Alignment padding in VLE code is se_nop (se_or r0,r0, 0x4400).  The bytes
# are identical to NXP GNU as 2.28 (-mvle -me200z4) for this input
# (plans/e200/probes/out/p05-align.txt).

# CHECK:      Contents of section .text:
# CHECK-NEXT: 0000 00044400 44004400 00044400 44004400
# CHECK-NEXT: 0010 18000000 44004400

	.text
	se_blr
	.p2align 3
	se_blr
	.p2align 4
	e_lbzu 0, 0(0)
	.p2align 3
