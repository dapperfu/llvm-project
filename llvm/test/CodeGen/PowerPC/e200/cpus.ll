; The documented e200 implementations and their family aliases are selectable
; with -mcpu, and aliases resolve to the same features as their canonical
; implementation (e200z4 -> e200z446n3, e200z7/e200z759 -> e200z759n3,
; e200z760 -> e200z760n3).

; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=help 2>&1 | FileCheck %s --check-prefix=HELP
; HELP-DAG: e200z0 {{.*}}- Select the e200z0 processor.
; HELP-DAG: e200z0h {{.*}}- Select the e200z0h processor.
; HELP-DAG: e200z1 {{.*}}- Select the e200z1 processor.
; HELP-DAG: e200z3 {{.*}}- Select the e200z3 processor.
; HELP-DAG: e200z4 {{.*}}- Select the e200z4 processor.
; HELP-DAG: e200z446n3 {{.*}}- Select the e200z446n3 processor.
; HELP-DAG: e200z6 {{.*}}- Select the e200z6 processor.
; HELP-DAG: e200z7 {{.*}}- Select the e200z7 processor.
; HELP-DAG: e200z759 {{.*}}- Select the e200z759 processor.
; HELP-DAG: e200z759n3 {{.*}}- Select the e200z759n3 processor.
; HELP-DAG: e200z760 {{.*}}- Select the e200z760 processor.
; HELP-DAG: e200z760n3 {{.*}}- Select the e200z760n3 processor.

; Book E capable cores compile without VLE.
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z1 < %s | FileCheck %s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z3 < %s | FileCheck %s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z446n3 < %s | FileCheck %s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z4 < %s | FileCheck %s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z6 < %s | FileCheck %s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z759n3 < %s | FileCheck %s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z7 < %s | FileCheck %s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z759 < %s | FileCheck %s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z760n3 < %s | FileCheck %s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z760 < %s | FileCheck %s

; An alias produces the same code as its canonical CPU.
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z4 < %s > %t.alias.s
; RUN: llc -mtriple=powerpc-unknown-eabi -mcpu=e200z446n3 < %s > %t.canon.s
; RUN: diff %t.alias.s %t.canon.s

define i32 @sel(i32 %a, i32 %b, i32 %c) {
; CHECK-LABEL: sel:
; CHECK: isel
  %cmp = icmp slt i32 %a, %b
  %r = select i1 %cmp, i32 %b, i32 %c
  ret i32 %r
}
