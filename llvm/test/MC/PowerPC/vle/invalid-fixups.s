# RUN: not llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -mattr=+vle -filetype=obj %s \
# RUN:   -o /dev/null 2>&1 | FileCheck %s --implicit-check-not=error:

# Split 16-bit fields need @l, @h, @ha or an @sdarel form; no relocation
# covers a bare symbol (VLEPIM Rev. 1 Table 2-4).
# CHECK: :[[@LINE+1]]:11: error: unsupported relocation type
	e_lis 3, sym
# CHECK: :[[@LINE+1]]:14: error: unsupported relocation type
	e_add2i. 3, sym

# Branches are not relaxed; displacements are signed halfword counts
# (VLEPEM Rev. 0 Table A-1), with the limits GNU as 2.28 reports.
# CHECK: :[[@LINE+1]]:8: error: branch target out of range (256 not between -256 and 254)
	se_b .+256
# CHECK: :[[@LINE+1]]:8: error: branch target not a multiple of two (1)
	se_b .+1
# CHECK: :[[@LINE+1]]:14: error: branch target out of range (32768 not between -32768 and 32766)
	e_bc 1, 2, .+0x8000
# CHECK: :[[@LINE+1]]:7: error: branch target out of range (16777216 not between -16777216 and 16777214)
	e_b .+0x1000000
