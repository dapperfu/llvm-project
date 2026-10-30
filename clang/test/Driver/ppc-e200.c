// Driver handling for NXP/Freescale e200 CPUs: CPU normalisation, VLE
// selection, float ABI, diagnostics, GNU assembler flags and feature listing.

// Family names resolve to the documented canonical implementation.
// RUN: %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z4 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=Z4
// Z4: "-target-cpu" "e200z446n3"
// RUN: %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z7 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=Z7
// Z7: "-target-cpu" "e200z759n3"
// RUN: %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z760 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=Z760
// Z760: "-target-cpu" "e200z760n3"

// Undocumented implementations are not targets.
// RUN: not %clang -c --target=powerpc-unknown-eabi -mcpu=e200z2 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=UNKNOWN
// RUN: not %clang -c --target=powerpc-unknown-eabi -mcpu=e200z4251n3 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=UNKNOWN
// UNKNOWN: error: unknown target CPU
// UNKNOWN: note: valid target CPU values are:

// -mvle/-mno-vle map to the vle target feature.
// RUN: %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z4 -mvle %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=VLE
// VLE: "-target-feature" "+vle"
// RUN: %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z4 -mvle -mno-vle %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=NOVLE
// NOVLE: "-target-feature" "-vle"

// e200 has no classic FPU: soft float by default, EFPU2 with -mhard-float.
// RUN: %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z4 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=SOFT
// SOFT: "-target-feature" "-hard-float"
// SOFT: "-msoft-float" "-mfloat-abi" "soft"
// RUN: %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z4 -mhard-float %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=HARD
// HARD: "-target-feature" "+hard-float"
// HARD: "-mfloat-abi" "hard"
// RUN: %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z4 -mspe %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=SPE
// SPE: "-target-feature" "+spe"
// SPE: "-mfloat-abi" "hard"
// Other CPUs keep the hard-float default.
// RUN: %clang -### -c --target=powerpc-unknown-eabi -mcpu=e500 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=E500
// E500-NOT: "-hard-float"
// E500: "-mfloat-abi" "hard"

// Invalid combinations are diagnosed against the CPU's documented features.
// RUN: not %clang -c --target=powerpc-unknown-eabi -mcpu=e200z6 -mvle %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ERR-VLE
// ERR-VLE: error: option '-mvle' is not supported by CPU 'e200z6', which does not implement the VLE category
// RUN: not %clang -c --target=powerpc-unknown-eabi -mcpu=e200z0 -mno-vle %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ERR-VLEONLY
// ERR-VLEONLY: error: option '-mno-vle' is not supported by CPU 'e200z0', which implements only VLE encodings
// RUN: not %clang -c --target=powerpc-unknown-eabi -mcpu=e200z1 -mspe %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ERR-SPE
// ERR-SPE: error: option '-mspe' is not supported by CPU 'e200z1', which does not implement the SPE category
// RUN: not %clang -c --target=powerpc-unknown-eabi -mcpu=e200z1 -mhard-float %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ERR-FP
// ERR-FP: error: option '-mhard-float' is not supported by CPU 'e200z1', which does not implement floating-point hardware
// RUN: not %clang -c --target=powerpcle-unknown-eabi -mcpu=e200z4 -mvle %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ERR-LE
// ERR-LE: error: option '-mvle' is not supported for little-endian targets; VLE encodings are big-endian only
// RUN: not %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z760 -mspe2 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ERR-SPE2
// ERR-SPE2: error: unsupported option '-mspe2': the SPE2 extension is not implemented because no authoritative encoding documentation is available
// RUN: not %clang -### -c --target=powerpc-unknown-eabi -mcpu=e200z4 -mlsp %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ERR-LSP
// ERR-LSP: error: unsupported option '-mlsp': the LSP extension is not implemented

// GNU assembler flags follow NXP's ASM_CPU_SPEC for VLE.
// RUN: %clang -### -c -fno-integrated-as --target=powerpc-unknown-eabi -mcpu=e200z4 -mvle %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=AS-Z4-VLE
// AS-Z4-VLE: as"{{.*}} "-mbig-endian" "-mvle" "-me200z4"
// RUN: %clang -### -c -fno-integrated-as --target=powerpc-unknown-eabi -mcpu=e200z0 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=AS-Z0
// AS-Z0: as"{{.*}} "-mbig-endian" "-mvle"
// AS-Z0-NOT: "-many"
// RUN: %clang -### -c -fno-integrated-as --target=powerpc-unknown-eabi -mcpu=e200z6 %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=AS-BOOKE
// AS-BOOKE: as"{{.*}} "-mbig-endian" "-me500x2"

// Target features can be listed for build systems and IDEs.
// RUN: %clang --target=powerpc-unknown-eabi -mcpu=e200z0 --print-enabled-extensions 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ENABLED
// ENABLED: Features enabled for the given PowerPC target
// ENABLED: e200z0-family {{ *}}e200z0 core family
// ENABLED: vle {{ *}}Use VLE (variable-length) instruction encodings
// ENABLED: vle-only {{ *}}Implement only VLE instruction encodings
// RUN: %clang --target=powerpc-unknown-eabi --print-supported-extensions 2>&1 \
// RUN:   | FileCheck %s --check-prefix=SUPPORTED
// SUPPORTED: All available PowerPC target features
// SUPPORTED: vle-isa {{ *}}Implement the VLE instruction category
