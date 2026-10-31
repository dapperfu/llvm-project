# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -mattr=+vle -filetype=obj %s -o %t.vle.o
# RUN: llvm-readelf -S %t.vle.o | FileCheck --check-prefix=VLE %s
# RUN: llvm-objdump -s -j .text -j .text.vle -j .PPC.EMB.apuinfo %t.vle.o \
# RUN:   | FileCheck --check-prefixes=VLE-DATA,APU %s
# RUN: llvm-mc -triple=powerpc-unknown-eabi -mcpu=e200z4 -filetype=obj %s -o %t.sec.o
# RUN: llvm-readelf -S %t.sec.o | FileCheck --check-prefix=SEC %s
# RUN: llvm-objdump -s -j .text -j .text.vle -j .PPC.EMB.apuinfo %t.sec.o \
# RUN:   | FileCheck --check-prefixes=SEC-DATA,APU %s

# SHF_PPC_VLE marks sections holding VLE code (VLEPIM Rev. 1 §2.2.2), shown
# as "V" by llvm-readelf.  With the "vle" feature every section that receives
# an instruction is VLE, as with GNU as -mvle.  Without it, an e200 core
# switches to VLE mode inside sections declared with the "v" flag.  Padding
# inside VLE code is se_nop (0x4400).  Each instruction adds its APU to
# .PPC.EMB.apuinfo: isel is APU 0x40 and VLE instructions APU 0x104 (VLEPIM
# Rev. 1 §2.2.1).

# VLE:      .text       PROGBITS {{.*}} AXV
# VLE:      .text.vle   PROGBITS {{.*}} AXV
# VLE:      .text.other PROGBITS {{.*}} AXV
# VLE:      .data       PROGBITS {{.*}}  WA
# VLE:      .rodata.v   PROGBITS {{.*}}  AV
# VLE:      .PPC.EMB.apuinfo NOTE

# SEC:      .text       PROGBITS {{.*}}  AX
# SEC:      .text.vle   PROGBITS {{.*}} AXV
# SEC:      .text.other PROGBITS {{.*}}  AX
# SEC:      .data       PROGBITS {{.*}}  WA
# SEC:      .rodata.v   PROGBITS {{.*}}  AV

# VLE-DATA:      Contents of section .text:
# VLE-DATA-NEXT: 0000 7c642a14 44004400 7c64289e
# SEC-DATA:      Contents of section .text:
# SEC-DATA-NEXT: 0000 7c642a14 60000000 7c64289e

# VLE-DATA:      Contents of section .text.vle:
# VLE-DATA-NEXT: 0000 04434400 44004400 0004
# SEC-DATA:      Contents of section .text.vle:
# SEC-DATA-NEXT: 0000 04434400 44004400 0004

# APU:      Contents of section .PPC.EMB.apuinfo:
# APU-NEXT: 0000 00000008 00000008 00000002 41505569
# APU-NEXT: 0010 6e666f00 00400001 01040001

	.text
	add 3, 4, 5
	.p2align 3
	isel 3, 4, 5, 2
	.section .text.vle,"axv"
	se_add 3, 4
	.p2align 3
	se_blr
	.section .text.other,"ax"
	or 3, 4, 5
	.data
	.long 1
	.section .rodata.v,"av"
	.long 2
