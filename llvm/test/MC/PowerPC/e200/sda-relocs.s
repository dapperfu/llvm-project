# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z446n3 -filetype=obj %s -o - \
# RUN:   | llvm-readobj -r - | FileCheck %s
# Small-data relocations in Book E code (e500 ABI): @sda21 relocates the RA
# and D fields of a D-form instruction together (R_PPC_EMB_SDA21 at the
# instruction), @sdarel the D field alone.  Matches NXP GNU as 2.28
# (plans/e200/probes/out/p08-emb-relocs.txt).

# CHECK:      Section ({{.*}}) .rela.text {
# CHECK-NEXT:   0x0 R_PPC_EMB_SDA21 .sdata 0x0
# CHECK-NEXT:   0x4 R_PPC_EMB_SDA21 .sdata 0x0
# CHECK-NEXT:   0xA R_PPC_SDAREL16 .sdata 0x0
# CHECK-NEXT:   0xC R_PPC_EMB_SDA21 .sdata2 0x0
# CHECK-NEXT: }

	.text
	lwz 3, sdav@sda21(0)
	addi 3, 0, sdav@sda21
	lwz 3, sdav@sdarel(13)
	lwz 4, sd2@sda21(0)

	.section .sdata,"aw"
sdav:
	.long 0
	.section .sdata2,"a"
sd2:
	.long 0
