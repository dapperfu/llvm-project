// RUN: rm -rf %t && split-file %s %t
// RUN: llvm-tblgen -gen-target-features -I %p/../../include %t/valid.td \
// RUN:   | FileCheck %t/valid.td
// RUN: not llvm-tblgen -gen-target-features -I %p/../../include %t/non-existent.td 2>&1 \
// RUN:   | FileCheck %t/non-existent.td -DFILE=%t/non-existent.td --implicit-check-not="error:"
// RUN: not llvm-tblgen -gen-target-features -I %p/../../include %t/dup-processor.td 2>&1 \
// RUN:   | FileCheck %t/dup-processor.td -DFILE=%t/dup-processor.td --implicit-check-not="error:"

// The target-features emitter (used by TargetParser libraries) resolves
// ProcessorAlias records to the canonical processor's features, emits an
// alias table, and emits feature descriptions.

//--- valid.td
include "llvm/Target/Target.td"
def MyTarget : Target;
def FeatA : SubtargetFeature<"feat-a", "HasA", "true", "Enable \"A\" things">;
def FeatB : SubtargetFeature<"feat-b", "HasB", "true", "Enable B">;
def : ProcessorModel<"cpu-x", NoSchedModel, [FeatA]>;
def : ProcessorModel<"cpu-y", NoSchedModel, [FeatB]>;
def : ProcessorAlias<"alias-x", "cpu-x">;

// The alias appears in the sorted subtype table with cpu-x's mask.
// CHECK-LABEL: BasicMyTargetSubTypeKV[] = {
// CHECK-NEXT:  { "alias-x", { { { 0x1ULL,
// CHECK-NEXT:  { "cpu-x", { { { 0x1ULL,
// CHECK-NEXT:  { "cpu-y", { { { 0x2ULL,
// CHECK:       #ifdef GET_SUBTARGETFEATURES_ALIASES
// CHECK:       BasicMyTargetProcessorAliases[] = {
// CHECK-NEXT:    { "alias-x", "cpu-x" },
// CHECK-NEXT:  };
// CHECK:       #ifdef GET_SUBTARGETFEATURES_DESCS
// CHECK:       BasicMyTargetFeatureDescs[] = {
// CHECK-NEXT:    { "feat-a", "Enable \"A\" things" },
// CHECK-NEXT:    { "feat-b", "Enable B" },
// CHECK-NEXT:  };

//--- non-existent.td
include "llvm/Target/Target.td"
def MyTarget : Target;
def ProcA : ProcessorModel<"cpu-a", NoSchedModel, []>;
// CHECK: [[FILE]]:[[#@LINE+1]]:1: error: Alias 'bad-alias' references a non-existent Processor 'cpu-missing'
def : ProcessorAlias<"bad-alias", "cpu-missing">;

//--- dup-processor.td
include "llvm/Target/Target.td"
def MyTarget : Target;
def ProcA : ProcessorModel<"cpu-a", NoSchedModel, []>;
// CHECK: [[FILE]]:[[#@LINE+1]]:1: error: Alias 'cpu-a' duplicates an existing Processor
def : ProcessorAlias<"cpu-a", "cpu-a">;
