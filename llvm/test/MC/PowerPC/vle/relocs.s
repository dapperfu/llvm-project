# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -mattr=+vle -filetype=obj %s -o - \
# RUN:   | llvm-readobj -r - | FileCheck %s
# VLE relocations (VLEPIM Rev. 1 Table 2-4).  The relocation field follows the
# instruction form: I16L operands take the A split relocations, I16A operands
# the D ones.  Types and offsets match NXP GNU as 2.28, except that @sda21 on a
# D-form load gives R_PPC_EMB_SDA21 as VLEPIM specifies (GNU as emits
# R_PPC_VLE_SDA21; plans/e200/discrepancies.md D1).

# CHECK:      Section ({{.*}}) .rela.text {
# CHECK-NEXT:   0x0 R_PPC_VLE_HA16A ext 0x0
# CHECK-NEXT:   0x4 R_PPC_VLE_HI16A ext 0x0
# CHECK-NEXT:   0x8 R_PPC_VLE_LO16A ext 0x0
# CHECK-NEXT:   0xC R_PPC_VLE_HI16A ext 0x0
# CHECK-NEXT:   0x10 R_PPC_VLE_LO16A ext 0x0
# CHECK-NEXT:   0x14 R_PPC_VLE_HI16A ext 0x0
# CHECK-NEXT:   0x18 R_PPC_VLE_LO16D ext 0x0
# CHECK-NEXT:   0x1C R_PPC_VLE_HA16D ext 0x0
# CHECK-NEXT:   0x20 R_PPC_VLE_LO16D ext 0x0
# CHECK-NEXT:   0x24 R_PPC_VLE_HI16D ext 0x0
# CHECK-NEXT:   0x28 R_PPC_VLE_SDAREL_LO16D .sdata 0x0
# CHECK-NEXT:   0x2C R_PPC_VLE_SDAREL_HI16D .sdata 0x0
# CHECK-NEXT:   0x30 R_PPC_VLE_SDAREL_HA16D .sdata 0x0
# CHECK-NEXT:   0x34 R_PPC_VLE_SDAREL_HA16A .sdata 0x0
# CHECK-NEXT:   0x38 R_PPC_VLE_SDAREL_LO16A .sdata 0x0
# CHECK-NEXT:   0x3C R_PPC_VLE_SDAREL_HI16A .sdata 0x0
# CHECK-NEXT:   0x42 R_PPC_ADDR16_LO ext 0x0
# CHECK-NEXT:   0x46 R_PPC_ADDR16_LO ext 0x0
# CHECK-NEXT:   0x48 R_PPC_VLE_REL24 ext 0x0
# CHECK-NEXT:   0x4C R_PPC_VLE_REL8 ext 0x0
# CHECK-NEXT:   0x4E R_PPC_VLE_REL24 ext 0x0
# CHECK-NEXT:   0x52 R_PPC_VLE_REL8 ext 0x0
# CHECK-NEXT:   0x54 R_PPC_VLE_REL15 ext 0x0
# CHECK-NEXT:   0x58 R_PPC_VLE_REL8 ext 0x0
# CHECK-NEXT:   0x5A R_PPC_VLE_SDA21 .sdata 0x0
# CHECK-NEXT:   0x5E R_PPC_VLE_SDA21 .sdata 0x0
# CHECK-NEXT:   0x62 R_PPC_EMB_SDA21 .sdata 0x0
# CHECK-NEXT:   0x68 R_PPC_SDAREL16 .sdata 0x0
# CHECK-NEXT:   0x6C R_PPC_SDAREL16 .sdata 0x0
# CHECK-NEXT: }

	.text
	e_lis 3, ext@ha
	e_lis 4, ext@h
	e_or2i 3, ext@l
	e_or2is 3, ext@h
	e_and2i. 3, ext@l
	e_and2is. 3, ext@h
	e_add2i. 3, ext@l
	e_add2is 3, ext@ha
	e_cmp16i 3, ext@l
	e_cmpl16i 3, ext@h
	e_add2i. 3, sdav@sdarel@l
	e_add2is 3, sdav@sdarel@h
	e_add2is 3, sdav@sdarel@ha
	e_lis 3, sdav@sdarel@ha
	e_or2i 3, sdav@sdarel@l
	e_or2is 3, sdav@sdarel@h
	e_add16i 3, 3, ext@l
	e_lwz 3, ext@l(3)
	e_bl ext
	se_bl ext
	e_b ext
	se_b ext
	e_bc 0, 2, ext
	se_bc 1, 2, ext
	e_add16i 3, 0, sdav@sda21
	e_li 3, sdav@sda21
	e_lwz 3, sdav@sda21(0)
	e_lwz 3, sdav@sdarel(13)
	e_add16i 3, 13, sdav@sdarel

	.section .sdata,"aw"
sdav:
	.long 0
