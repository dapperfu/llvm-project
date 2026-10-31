# RUN: not llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -mattr=+vle %s 2>&1 \
# RUN:   | FileCheck %s --implicit-check-not=error:

# 16-bit register fields name r0-r7 and r24-r31 (RX/RY/RZ) or r8-r23
# (ARX/ARY) (VLEPEM Rev. 0 Table A-1).
# CHECK: :[[@LINE+1]]:11: error: invalid operand for instruction
se_add 3, 8
# CHECK: :[[@LINE+1]]:9: error: invalid operand for instruction
se_mtar 7, 3
# CHECK: :[[@LINE+1]]:12: error: invalid operand for instruction
se_mfar 3, 24
# CHECK: :[[@LINE+1]]:13: error: invalid operand for instruction
se_lbz 3, 0(8)

# Immediate ranges.  GNU as encodes "se_addi rX, 0" as an add of 32; OIM5
# only represents 1-32 (plans/e200/discrepancies.md D11).
# CHECK: :[[@LINE+1]]:12: error: invalid operand for instruction
se_addi 3, 0
# CHECK: :[[@LINE+1]]:12: error: invalid operand for instruction
se_addi 3, 33
# CHECK: :[[@LINE+1]]:10: error: invalid operand for instruction
se_li 3, 128
# CHECK: :[[@LINE+1]]:11: error: invalid operand for instruction
se_lwz 3, 2(4)
# CHECK: :[[@LINE+1]]:11: error: invalid operand for instruction
se_lwz 3, 64(4)
# CHECK: :[[@LINE+1]]:11: error: invalid operand for instruction
e_lbzu 3, 128(4)
# CHECK: :[[@LINE+1]]:14: error: invalid operand for instruction
e_addi 3, 4, 0x101
# CHECK: :[[@LINE+1]]:10: error: invalid operand for instruction
e_lis 3, -1
# CHECK: :[[@LINE+1]]:10: error: invalid operand for instruction
e_lis 3, 0x10000
# CHECK: :[[@LINE+1]]:9: error: invalid operand for instruction
e_li 3, 0x80000

# Only @sda21 can relocate the LI20 field (plans/e200/discrepancies.md D2).
# CHECK: :[[@LINE+1]]:9: error: invalid operand for instruction
e_li 3, sym@l

# BF32 and BI32 name CR fields 0-3; BI16 names a bit of CR0.
# CHECK: :[[@LINE+1]]:8: error: invalid operand for instruction
e_cmpi 4, 3, 1
# CHECK: :[[@LINE+1]]:9: error: invalid operand for instruction
e_bc 1, 16, .
# CHECK: :[[@LINE+1]]:12: error: invalid operand for instruction
e_bgt cr4, .
# CHECK: :[[@LINE+1]]:10: error: invalid operand for instruction
se_bc 1, 4, .

# e_mulli and e_rlwinm have no record forms; e_sc is not in the manuals.
# CHECK: :[[@LINE+1]]:8: error: invalid operand for instruction
e_mulli. 3, 4, 1
# CHECK: :[[@LINE+1]]:9: error: invalid operand for instruction
e_rlwinm. 3, 4, 1, 0, 31
# CHECK: :[[@LINE+1]]:1: error: invalid instruction
e_sc

# Book E instructions that VLEPEM Rev. 0 Table B-2 does not list as shared.
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
addi 3, 4, 1
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
b .
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
blr
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
lwz 3, 0(4)
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
rfi
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
sc
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
isync
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
mcrf 0, 1
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
rlwinm 3, 4, 1, 0, 31
# CHECK: :[[@LINE+1]]:1: error: instruction is not available in VLE mode
li 3, 1
