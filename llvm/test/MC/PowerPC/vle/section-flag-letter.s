# RUN: llvm-mc -triple=powerpc-unknown-eabi %s | FileCheck %s
# RUN: llvm-mc -triple=powerpc-unknown-eabi -filetype=obj %s -o - \
# RUN:   | llvm-readobj -S - | FileCheck --check-prefix=OBJ %s
# RUN: not llvm-mc -triple=powerpc64-unknown-linux-gnu %s -o /dev/null 2>&1 \
# RUN:   | FileCheck --check-prefix=PPC64 %s

# The "v" section flag letter sets SHF_PPC_VLE (VLEPIM Rev. 1 §2.2.2), as in
# GNU as; it is specific to 32-bit PowerPC.

# CHECK: .section .text.vle,"axv",@progbits
# CHECK: .section .rodata.v,"av",@progbits

# OBJ:      Name: .text.vle
# OBJ-NEXT: Type: SHT_PROGBITS
# OBJ-NEXT: Flags [ (0x10000006)
# OBJ:      Name: .rodata.v
# OBJ-NEXT: Type: SHT_PROGBITS
# OBJ-NEXT: Flags [ (0x10000002)

# PPC64: :[[@LINE+2]]:26: error: unknown flag

	.section .text.vle,"axv"
	.section .rodata.v,"av"
