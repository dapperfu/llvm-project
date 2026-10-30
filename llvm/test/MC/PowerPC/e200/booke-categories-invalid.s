# Each e200 core rejects instructions of ISA categories its reference manual
# does not implement (plans/e200/capability-matrix.yaml).  Instructions not
# listed for a core below must assemble.  e200z0 (VLE only) is covered by the
# VLE tests.

# RUN: not llvm-mc -triple powerpc-unknown-eabi -mcpu=e200z1 %s 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=ALL,Z1 -DCPU=e200z1 --implicit-check-not=error:
# RUN: not llvm-mc -triple powerpc-unknown-eabi -mcpu=e200z3 %s 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=ALL,Z3 -DCPU=e200z3 --implicit-check-not=error:
# RUN: not llvm-mc -triple powerpc-unknown-eabi -mcpu=e200z446n3 %s 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=ALL,Z4 -DCPU=e200z446n3 --implicit-check-not=error:
# RUN: not llvm-mc -triple powerpc-unknown-eabi -mcpu=e200z6 %s 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=ALL,Z6 -DCPU=e200z6 --implicit-check-not=error:
# RUN: not llvm-mc -triple powerpc-unknown-eabi -mcpu=e200z759n3 %s 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=ALL,Z7 -DCPU=e200z759n3 --implicit-check-not=error:
# RUN: not llvm-mc -triple powerpc-unknown-eabi -mcpu=e200z760n3 %s 2>&1 \
# RUN:   | FileCheck %s --check-prefixes=ALL,Z7 -DCPU=e200z760n3 --implicit-check-not=error:
# No classic FPU, move assist, vector or embedded double precision on any
# e200 (e200z1RM Table 3-1, UM0434 Table 100, e200z4RM Table 3-1/6-15,
# e200z6RM Table 3-1, e200z759n3CRM Table 18).
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
fadd 1, 2, 3
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
lswi 3, 4, 8
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
vaddubm 1, 2, 3
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
efdadd 3, 4, 5

# No 64-bit instructions: every e200 is a 32-bit core.
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
ld 3, 0(4)
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mulld 3, 4, 5
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
rldicl 3, 4, 1, 0

# No Book III-S (server) or 4xx/6xx-specific instructions.
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
rfid
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
tlbie 3
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
slbia
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mtmsrd 3
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mfsr 3, 1
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
tlbld 3
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
tlbilxva 3
# ALL: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mfbr0 3

# SPE and embedded single-precision floating point: not on e200z1
# (e200z1RM §3.13 p.84).
# Z1: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
efsadd 3, 4, 5
# Z1: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
evaddw 3, 4, 5

# wait: not on e200z3 (UM0434 §5.13 p.122), undocumented on e200z6.
# Z3: :[[@LINE+2]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z6: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
wait

# DCRs: not on e200z6 (e200z6RM Table 3-1 p.123-124).
# Z6: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mfdcr 3, 1

# Machine check APU and partword reservations: e200z4/e200z7 only
# (e200z4RM §3.12, §3.14).
# Z1: :[[@LINE+3]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z3: :[[@LINE+2]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z6: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
rfmci
# Z1: :[[@LINE+3]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z3: :[[@LINE+2]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z6: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
lbarx 3, 0, 4

# Performance monitor: e200z759n3/e200z760n3 only (e200z759n3CRM Ch.8;
# absent on e200z446n3, e200z4RM §3.9 p.97).
# Z1: :[[@LINE+4]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z3: :[[@LINE+3]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z4: :[[@LINE+2]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z6: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mfpmr 3, 16

# Instructions every Book E e200 core implements.
isel 3, 4, 5, 2
mbar
msync
rfi
rfci
rfdi
tlbre
tlbwe
tlbsx 3, 4
tlbivax 3, 4
tlbsync
mfhid0 3
mtspr 63, 3

# Core-specific SPR mnemonics.  SPR 568 is IAC8 on e200z4/e200z7 and
# ALTCTXCR on e200z1/e200z6; IVORs do not exist on e200z1.
# Z1: :[[@LINE+3]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z3: :[[@LINE+2]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z6: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mfiac8 3
# Z3: :[[@LINE+3]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z4: :[[@LINE+2]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z7: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mfaltctxcr 3
# Z1: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mfivor4 3
# Z1: :[[@LINE+4]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z3: :[[@LINE+3]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z4: :[[@LINE+2]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
# Z6: :[[@LINE+1]]:1: error: instruction is not supported by the selected CPU '[[CPU]]'
mfivor35 3
