//===---------- llvm/unittest/TargetParser/PPCTargetParserTest.cpp --------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/TargetParser/PPCTargetParser.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/TargetParser/Triple.h"
#include "gtest/gtest.h"

using namespace llvm;

namespace {

const Triple EABI("powerpc-unknown-eabi");

// Canonical e200 implementations documented by the reference manuals listed in
// plans/e200/source-register.yaml.
const char *const E200CPUs[] = {"e200z0",     "e200z0h",    "e200z1",
                                "e200z3",     "e200z446n3", "e200z6",
                                "e200z759n3", "e200z760n3"};

TEST(PPCTargetParser, E200AliasesResolveToCanonicalCPUs) {
  EXPECT_EQ(PPC::normalizeCPUName("e200z4"), "e200z446n3");
  EXPECT_EQ(PPC::normalizeCPUName("e200z7"), "e200z759n3");
  EXPECT_EQ(PPC::normalizeCPUName("e200z759"), "e200z759n3");
  EXPECT_EQ(PPC::normalizeCPUName("e200z760"), "e200z760n3");
  EXPECT_EQ(PPC::getNormalizedPPCTargetCPU(EABI, "e200z4"), "e200z446n3");
  for (const char *CPU : E200CPUs)
    EXPECT_EQ(PPC::resolveProcessorAlias(CPU), CPU);
}

TEST(PPCTargetParser, E200CPUsAreValid) {
  for (const char *CPU : E200CPUs)
    EXPECT_TRUE(PPC::isValidCPU(CPU)) << CPU;
  for (const char *Alias : {"e200z4", "e200z7", "e200z759", "e200z760"})
    EXPECT_TRUE(PPC::isValidCPU(Alias)) << Alias;
  // Implementations without a reference manual are not targets.
  for (const char *Omitted : {"e200z2", "e200z4251n3", "e200z210n3"})
    EXPECT_FALSE(PPC::isValidCPU(Omitted)) << Omitted;
}

TEST(PPCTargetParser, E200AliasFeaturesMatchCanonical) {
  for (auto [Alias, Canonical] :
       {std::pair{"e200z4", "e200z446n3"}, std::pair{"e200z7", "e200z759n3"},
        std::pair{"e200z760", "e200z760n3"}}) {
    auto AliasFeatures = PPC::getPPCDefaultTargetFeatures(EABI, Alias);
    auto CanonicalFeatures = PPC::getPPCDefaultTargetFeatures(EABI, Canonical);
    ASSERT_TRUE(AliasFeatures && CanonicalFeatures) << Alias;
    EXPECT_EQ(AliasFeatures->size(), CanonicalFeatures->size()) << Alias;
    for (const auto &F : *CanonicalFeatures)
      EXPECT_EQ(AliasFeatures->lookup(F.getKey()), F.getValue())
          << Alias << ": " << F.getKey().str();
  }
}

TEST(PPCTargetParser, E200Capabilities) {
  auto Has = [](StringRef CPU, StringRef Feature) {
    auto Features = PPC::getPPCDefaultTargetFeatures(EABI, CPU);
    return Features && Features->lookup(Feature);
  };
  // No e200 core has a classic FPU, so none defaults to hard float.
  for (const char *CPU : E200CPUs) {
    EXPECT_TRUE(Has(CPU, "e200")) << CPU;
    EXPECT_TRUE(Has(CPU, "strict-isa-categories")) << CPU;
    EXPECT_FALSE(Has(CPU, "hard-float")) << CPU;
    EXPECT_FALSE(Has(CPU, "spe")) << CPU;
    EXPECT_FALSE(Has(CPU, "spe-double")) << CPU;
  }
  // e200z0CORERM Rev. 0 p.23: VLE only.
  EXPECT_TRUE(Has("e200z0", "vle-only"));
  EXPECT_TRUE(Has("e200z0", "vle"));
  // e200z1RM Rev. 0 p.21: Book E + VLE, no SPE.
  EXPECT_TRUE(Has("e200z1", "vle-isa"));
  EXPECT_FALSE(Has("e200z1", "vle"));
  EXPECT_FALSE(Has("e200z1", "spe-isa"));
  // e200z6RM Rev. 0: VLE not documented; SPE present.
  EXPECT_FALSE(Has("e200z6", "vle-isa"));
  EXPECT_TRUE(Has("e200z6", "spe-isa"));
  // e200z4RM Rev. 0 p.38: EFPU2; e200z759n3CRM Rev. 2 Ch.8: performance
  // monitor, absent on e200z446n3 (e200z4RM §3.9 p.97).
  EXPECT_TRUE(Has("e200z446n3", "efpu2-ext"));
  EXPECT_FALSE(Has("e200z446n3", "perfmon"));
  EXPECT_TRUE(Has("e200z759n3", "perfmon"));
}

TEST(PPCTargetParser, FeatureDescriptions) {
  EXPECT_EQ(PPC::getFeatureDescription("vle"),
            "Use VLE (variable-length) instruction encodings");
  EXPECT_EQ(PPC::getFeatureDescription("no-such-feature"), "");
}

} // namespace
