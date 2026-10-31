# RUN: not llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefix=NOVLE --implicit-check-not=error:
# RUN: not llvm-mc -triple=powerpc-unknown-eabi -mcpu=e500 %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefix=NOISA --implicit-check-not=error:

# VLE instructions need VLE mode: the "vle" feature or a section with the
# "v" flag (VLEPIM Rev. 1 §2.2.2), on a core that implements the VLE
# category.

	.text
# NOVLE: :[[@LINE+2]]:2: error: instruction requires VLE mode
# NOISA: :[[@LINE+1]]:2: error: instruction requires a CPU with the VLE category
	se_add 3, 4
# NOVLE: :[[@LINE+2]]:2: error: instruction requires VLE mode
# NOISA: :[[@LINE+1]]:2: error: instruction requires a CPU with the VLE category
	e_b .

	.section .text.vle,"axv"
# NOISA: :[[@LINE+1]]:2: error: VLE section requires a CPU with the VLE category
	se_add 3, 4
