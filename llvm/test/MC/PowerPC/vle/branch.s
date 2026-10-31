# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -mattr=+vle -show-encoding %s \
# RUN:   | FileCheck %s
# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -mattr=+vle -filetype=obj %s -o - \
# RUN:   | llvm-objdump -s -j .text - | FileCheck --check-prefix=OBJ %s
# BD8, BD15, BD24 and C-form branches (VLEPEM Rev. 0 Figures A-1, A-2, A-9
# and A-10).  Displacements count halfwords.  The resolved bytes, including
# the range limits, are identical to NXP GNU as 2.28 (-mvle -me200z4).

	.text
start:
# CHECK: e_b start # encoding: [0b0111100A,A,A,0bAAAAAAA0]
# CHECK-NEXT: fixup A - offset: 0, value: start, kind: fixup_ppc_vle_rel24
	e_b start
# CHECK: e_bl start # encoding: [0b0111100A,A,A,0bAAAAAAA1]
# CHECK-NEXT: fixup A - offset: 0, value: start, kind: fixup_ppc_vle_rel24
	e_bl start
# CHECK: se_b start # encoding: [0xe8,A]
# CHECK-NEXT: fixup A - offset: 0, value: start, kind: fixup_ppc_vle_rel8
	se_b start
# CHECK: se_bl start # encoding: [0xe9,A]
# CHECK-NEXT: fixup A - offset: 0, value: start, kind: fixup_ppc_vle_rel8
	se_bl start
# CHECK: e_bne start # encoding: [0x7a,0x02,A,0bAAAAAAA0]
# CHECK-NEXT: fixup A - offset: 0, value: start, kind: fixup_ppc_vle_rel15
	e_bc 0, 2, start
# CHECK: e_bcl 1, 6, start # encoding: [0x7a,0x16,A,0bAAAAAAA1]
	e_bcl 1, 6, start
# CHECK: se_bso start # encoding: [0xe7,A]
	se_bc 1, 3, start
# CHECK: e_beq 1, start # encoding: [0x7a,0x16,A,0bAAAAAAA0]
	e_beq cr1, start
# CHECK: e_bnel 3, start # encoding: [0x7a,0x0e,A,0bAAAAAAA1]
	e_bnel cr3, start
# CHECK: e_bdnz start # encoding: [0x7a,0x20,A,0bAAAAAAA0]
	e_bdnz start
# CHECK: se_bge start # encoding: [0xe0,A]
	se_bge start
# CHECK: se_blr # encoding: [0x00,0x04]
	se_blr
# CHECK: se_blrl # encoding: [0x00,0x05]
	se_blrl
# CHECK: se_bctr # encoding: [0x00,0x06]
	se_bctr
# CHECK: se_bctrl # encoding: [0x00,0x07]
	se_bctrl
	e_b end
	se_b end
# CHECK: e_bc 1, 15, end # encoding: [0x7a,0x1f,A,0bAAAAAAA0]
	e_bc 1, 15, end
	se_b .+254
	se_b .-256
	e_bc 1, 2, .+0x7ffe
	e_bc 1, 2, .-0x8000
	e_b .+0xfffffe
	e_b .-0x1000000
end:

# OBJ:      0000 78000000 79fffffd e8fce9fb 7a02fff4
# OBJ-NEXT: 0010 7a16fff1 e7f67a16 ffea7a0e ffe77a20
# OBJ-NEXT: 0020 ffe2e0ef 00040005 00060007 7800001e
# OBJ-NEXT: 0030 e80d7a1f 0018e87f e8807a12 7ffe7a12
# OBJ-NEXT: 0040 800078ff fffe7900 0000
