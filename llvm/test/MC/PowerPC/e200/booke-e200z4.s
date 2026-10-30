# Book E instructions and SPR mnemonics accepted for e200z446n3 (Book E
# pages).  Encodings agree with NXP GNU as 2.28 (-me500x2 / -mvle -me200z4;
# plans/e200/probes).  Sources: e200z4RM Rev. 0 Ch.3 (p.93-115), Table 2-15
# (p.85-89); EREF 2.0 Rev. 0.

# RUN: llvm-mc -triple powerpc-unknown-eabi -mcpu=e200z446n3 --show-encoding %s \
# RUN:   | FileCheck %s
# RUN: llvm-mc -triple powerpc-unknown-eabi -mcpu=e200z446n3 -filetype=obj %s -o %t.o
# RUN: llvm-objdump -d --mcpu=e200z446n3 %t.o | FileCheck %s --check-prefix=DIS

# CHECK: iseleq 3, 4, 5                  # encoding: [0x7c,0x64,0x28,0x9e]
# DIS: 7c 64 28 9e     iseleq 3, 4, 5
         isel 3, 4, 5, 2
# The embedded wait is opcode 31, XO 62 (e200z4RM Rev. 0 §3.13 p.104), not
# the Power ISA 3.0 wait (XO 30).
# CHECK: wait                            # encoding: [0x7c,0x00,0x00,0x7c]
# DIS: 7c 00 00 7c     wait
         wait
# mbar 0 shares its encoding with eieio, which the disassembler prints.
# CHECK: mbar                            # encoding: [0x7c,0x00,0x06,0xac]
# DIS: 7c 00 06 ac     eieio
         mbar
# CHECK: sync                            # encoding: [0x7c,0x00,0x04,0xac]
# DIS: 7c 00 04 ac     sync
         msync
# CHECK: rfi                             # encoding: [0x4c,0x00,0x00,0x64]
         rfi
# CHECK: rfci                            # encoding: [0x4c,0x00,0x00,0x66]
         rfci
# CHECK: rfdi                            # encoding: [0x4c,0x00,0x00,0x4e]
         rfdi
# CHECK: rfmci                           # encoding: [0x4c,0x00,0x00,0x4c]
         rfmci
# CHECK: mfdcr 3, 1                      # encoding: [0x7c,0x61,0x02,0x86]
         mfdcr 3, 1
# CHECK: tlbre                           # encoding: [0x7c,0x00,0x07,0x64]
         tlbre
# CHECK: tlbwe                           # encoding: [0x7c,0x00,0x07,0xa4]
         tlbwe
# CHECK: tlbsx 3, 4                      # encoding: [0x7c,0x03,0x27,0x24]
         tlbsx 3, 4
# CHECK: tlbivax 3, 4                    # encoding: [0x7c,0x03,0x26,0x24]
         tlbivax 3, 4
# CHECK: tlbsync                         # encoding: [0x7c,0x00,0x04,0x6c]
         tlbsync
# CHECK: lbarx 3, 0, 4                   # encoding: [0x7c,0x60,0x20,0x68]
         lbarx 3, 0, 4
# CHECK: sthcx. 3, 0, 4                  # encoding: [0x7c,0x60,0x25,0xad]
         sthcx. 3, 0, 4
# CHECK: efsadd 3, 4, 5                  # encoding: [0x10,0x64,0x2a,0xc0]
         efsadd 3, 4, 5
# CHECK: evaddw 3, 4, 5                  # encoding: [0x10,0x64,0x2a,0x00]
         evaddw 3, 4, 5

# SPR extended mnemonics; disassembly prints them for e200 CPUs.
# CHECK: mfhid0 3                        # encoding: [0x7c,0x70,0xfa,0xa6]
# DIS: 7c 70 fa a6     mfhid0 3
         mfhid0 3
# CHECK: mtl1csr0 3                      # encoding: [0x7c,0x72,0xfb,0xa6]
# DIS: 7c 72 fb a6     mtl1csr0 3
         mtl1csr0 3
# CHECK: mfiac8 3                        # encoding: [0x7c,0x78,0x8a,0xa6]
# DIS: 7c 78 8a a6     mfiac8 3
         mfiac8 3
# CHECK: mtivpr 3                        # encoding: [0x7c,0x7f,0x0b,0xa6]
         mtivpr 3
# CHECK: mfivor32 3                      # encoding: [0x7c,0x70,0x82,0xa6]
         mfivor32 3
# CHECK: mfmcsrr0 3                      # encoding: [0x7c,0x7a,0x8a,0xa6]
         mfmcsrr0 3
# CHECK: mfsvr 3                         # encoding: [0x7c,0x7f,0xfa,0xa6]
         mfsvr 3
