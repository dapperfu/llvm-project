// Predefined macros for NXP/Freescale e200 CPUs.  __PPCE200Z<n>__, __VLE__,
// __PPCVLE__, __NO_LWSYNC__ (VLE), __PPC_EABI__ and __SIZEOF_LONG_DOUBLE__ 8
// match NXP's powerpc-eabivle GCC 4.9.4 (plans/e200/probes/out/p10-macros.txt);
// __PPC_E200__ and __PPC_VLE__ are LLVM spellings.

// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z0 %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z0,VLE,SOFT,EABI --implicit-check-not=__SPE__
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z0h %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z0,VLE,SOFT --implicit-check-not=__SPE__
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z1 %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z1,SOFT --implicit-check-not=__VLE__
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z1 -mvle %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z1,VLE,SOFT
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z3 %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z3,SOFT --implicit-check-not=__VLE__
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z4 %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z4,SOFT --implicit-check-not=__VLE__
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z446n3 -mvle %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z4,VLE,SOFT
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z6 %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z6,SOFT --implicit-check-not=__VLE__
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z7 -mvle %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z7,VLE,SOFT
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z760 %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z7,SOFT --implicit-check-not=__VLE__

// -mhard-float and -mspe select the EFPU2 single-precision ABI.
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z4 -mhard-float %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z4,EFPU2 --implicit-check-not=_SOFT_FLOAT
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e200z4 -mspe -mvle %s \
// RUN:   | FileCheck %s --check-prefixes=E200,Z4,EFPU2,VLE --implicit-check-not=_SOFT_FLOAT

// Non-e200 EABI targets also get the GCC EABI macros, but no e200 macros.
// RUN: %clang -E -dM --target=powerpc-unknown-eabi -mcpu=e500 %s \
// RUN:   | FileCheck %s --check-prefixes=EABI --implicit-check-not=__PPC_E200__ \
// RUN:       --implicit-check-not=__PPCE200Z

// E200-DAG: #define __PPC_E200__ 1
// Z0-DAG: #define __PPCE200Z0__ 1
// Z1-DAG: #define __PPCE200Z1__ 1
// Z3-DAG: #define __PPCE200Z3__ 1
// Z4-DAG: #define __PPCE200Z4__ 1
// Z6-DAG: #define __PPCE200Z6__ 1
// Z7-DAG: #define __PPCE200Z7__ 1
// E200-DAG: #define __SIZEOF_LONG_DOUBLE__ 8
// VLE-DAG: #define __NO_LWSYNC__ 1
// VLE-DAG: #define __PPCVLE__ 1
// VLE-DAG: #define __PPC_VLE__ 1
// VLE-DAG: #define __VLE__ 1
// SOFT-DAG: #define _SOFT_DOUBLE 1
// SOFT-DAG: #define _SOFT_FLOAT 1
// SOFT-DAG: #define __NO_FPRS__ 1
// EFPU2-DAG: #define _SOFT_DOUBLE 1
// EFPU2-DAG: #define __NO_FPRS__ 1
// EFPU2-DAG: #define __SPE__ 1
// EABI-DAG: #define __PPC_EABI__ 1
// EABI-DAG: #define __embedded__ 1
