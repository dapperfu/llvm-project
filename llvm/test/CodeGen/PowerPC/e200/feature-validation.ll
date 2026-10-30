; Feature combinations that the selected e200 core does not implement are
; rejected; valid ones compile.  Capabilities: e200z0CORERM Rev. 0 p.23 (VLE
; only), e200z1RM Rev. 0 p.21 (no SPE), e200z6RM Rev. 0 (no VLE), e200z4RM
; Rev. 0 p.38 (SPE 1.1/EFPU2, no classic FPU).

; RUN: not llc -mtriple=powerpc-unknown-eabi -mcpu=e200z6 -mattr=+vle < %s 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NOVLE
; RUN: not llc -mtriple=powerpc-unknown-eabi -mcpu=e200z6 -mattr=+vle,+vle-isa < %s 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NOVLE-CPU
; RUN: not llc -mtriple=powerpc-unknown-eabi -mcpu=e200z0 -mattr=-vle < %s 2>&1 \
; RUN:   | FileCheck %s --check-prefix=VLEONLY
; RUN: not llc -mtriple=powerpcle-unknown-eabi -mcpu=e200z1 -mattr=+vle < %s 2>&1 \
; RUN:   | FileCheck %s --check-prefix=LE
; RUN: not llc -mtriple=powerpc-unknown-eabi -mcpu=e200z1 -mattr=+spe < %s 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NOSPE
; RUN: not llc -mtriple=powerpc-unknown-eabi -mcpu=e200z4 -mattr=+hard-float < %s 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NOFPU
; RUN: not llc -mtriple=powerpc-unknown-eabi -mcpu=e200z1 -mattr=+vle < %s 2>&1 \
; RUN:   | FileCheck %s --check-prefix=VLECG

; Valid combinations: soft-float by default, EFPU2 single precision on z4.
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z1 < %s | FileCheck %s --check-prefix=SOFT
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z4 < %s | FileCheck %s --check-prefix=SOFT
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z4 -mattr=+efpu2 < %s \
; RUN:   | FileCheck %s --check-prefix=EFPU2
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z6 -mattr=+efpu2 < %s \
; RUN:   | FileCheck %s --check-prefix=EFPU2

; NOVLE: LLVM ERROR: VLE encodings require a CPU that implements the VLE category
; NOVLE-CPU: LLVM ERROR: CPU 'e200z6' does not implement the VLE category
; VLEONLY: LLVM ERROR: CPU 'e200z0' implements only VLE encodings; VLE cannot be disabled
; LE: LLVM ERROR: VLE encodings are big-endian only
; NOSPE: LLVM ERROR: CPU 'e200z1' does not implement the SPE category
; NOFPU: LLVM ERROR: CPU 'e200z4' has no classic floating-point unit
; VLECG: LLVM ERROR: VLE code generation is not supported yet

define float @fadd(float %a, float %b) {
; SOFT-LABEL: fadd:
; SOFT: bl __addsf3
; EFPU2-LABEL: fadd:
; EFPU2: efsadd 3, 3, 4
  %c = fadd float %a, %b
  ret float %c
}
