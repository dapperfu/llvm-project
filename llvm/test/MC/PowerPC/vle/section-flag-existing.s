# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 %s | FileCheck %s
# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -filetype=obj %s -o - \
# RUN:   | llvm-readelf -S - | FileCheck --check-prefix=OBJ %s
# RUN: not llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 --defsym ERR=1 %s \
# RUN:   -o /dev/null 2>&1 | FileCheck --check-prefix=ERR %s

# GCC for e200 emits .section ".text","axv": an existing section can be
# marked VLE, as GNU as allows, and later entered without the flag.  Other
# flag changes are still errors.

# CHECK:      .section .text,"axv",@progbits
# CHECK-NEXT: se_blr
# CHECK-NEXT: se_blr

# OBJ: .text PROGBITS {{.*}} AXV

	.section ".text","axv"
	se_blr
	.section .text,"ax"
	se_blr

.ifdef ERR
# ERR: :[[@LINE+1]]:2: error: changed section flags for .text, expected: 0x10000006
	.section .text,"axw"
.endif
