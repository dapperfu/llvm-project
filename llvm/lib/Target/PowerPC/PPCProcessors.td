//===-- PPCProcessors.td - PowerPC Processor Definitions ---*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// PowerPC processors supported.
//

def : Processor<"generic", G3Itineraries, [Directive32, FeatureHardFloat,
                                           FeatureMFTB]>;
def : ProcessorModel<"440", PPC440Model, [Directive440, FeatureISEL,
                                          FeatureFRES, FeatureFRSQRTE,
                                          FeatureICBT, FeatureBookE,
                                          FeatureMSYNC, FeatureMFTB]>;
def : ProcessorModel<"450", PPC440Model, [Directive440, FeatureISEL,
                                          FeatureFRES, FeatureFRSQRTE,
                                          FeatureICBT, FeatureBookE,
                                          FeatureMSYNC, FeatureMFTB]>;
def : Processor<"601", G3Itineraries, [Directive601, FeatureFPU]>;
def : Processor<"602", G3Itineraries, [Directive602, FeatureFPU,
                                       FeatureMFTB]>;
def : Processor<"603", G3Itineraries, [Directive603,
                                       FeatureFRES, FeatureFRSQRTE,
                                       FeatureMFTB]>;
def : Processor<"603e", G3Itineraries, [Directive603,
                                        FeatureFRES, FeatureFRSQRTE,
                                        FeatureMFTB]>;
def : Processor<"603ev", G3Itineraries, [Directive603,
                                         FeatureFRES, FeatureFRSQRTE,
                                         FeatureMFTB]>;
def : Processor<"604", G3Itineraries, [Directive604,
                                       FeatureFRES, FeatureFRSQRTE,
                                       FeatureMFTB]>;
def : Processor<"604e", G3Itineraries, [Directive604,
                                        FeatureFRES, FeatureFRSQRTE,
                                        FeatureMFTB]>;
def : Processor<"620", G3Itineraries, [Directive620,
                                       FeatureFRES, FeatureFRSQRTE,
                                       FeatureMFTB]>;
def : Processor<"750", G4Itineraries, [Directive750,
                                       FeatureFRES, FeatureFRSQRTE,
                                       FeatureMFTB]>;
def : Processor<"g3", G3Itineraries, [Directive750,
                                      FeatureFRES, FeatureFRSQRTE,
                                      FeatureMFTB]>;
def : Processor<"7400", G4Itineraries, [Directive7400, FeatureAltivec,
                                        FeatureFRES, FeatureFRSQRTE,
                                        FeatureMFTB]>;
def : Processor<"g4", G4Itineraries, [Directive7400, FeatureAltivec,
                                      FeatureFRES, FeatureFRSQRTE,
                                      FeatureMFTB]>;
def : Processor<"7450", G4PlusItineraries, [Directive7400, FeatureAltivec,
                                            FeatureFRES, FeatureFRSQRTE,
                                            FeatureMFTB]>;
def : Processor<"g4+", G4PlusItineraries, [Directive7400, FeatureAltivec,
                                           FeatureFRES, FeatureFRSQRTE,
                                           FeatureMFTB]>;

def : ProcessorModel<"970", G5Model,
                  [Directive970, FeatureAltivec,
                   FeatureMFOCRF, FeatureFSqrt,
                   FeatureFRES, FeatureFRSQRTE, FeatureSTFIWX,
                   Feature64BitSupport /*, Feature64BitRegs */,
                   FeatureMFTB]>;
def : ProcessorModel<"g5", G5Model,
                  [Directive970, FeatureAltivec,
                   FeatureMFOCRF, FeatureFSqrt, FeatureSTFIWX,
                   FeatureFRES, FeatureFRSQRTE,
                   Feature64BitSupport /*, Feature64BitRegs */,
                   FeatureMFTB, DeprecatedDST]>;
def : ProcessorModel<"e500", PPCE500Model,
                  [DirectiveE500,
                   FeatureICBT, FeatureBookE,
                   FeatureISEL, FeatureMFTB, FeatureMSYNC, FeatureSPE]>;
def : ProcessorModel<"e500mc", PPCE500mcModel,
                  [DirectiveE500mc,
                   FeatureSTFIWX, FeatureICBT, FeatureBookE,
                   FeatureISEL, FeatureMFTB]>;
def : ProcessorModel<"e5500", PPCE5500Model,
                  [DirectiveE5500, FeatureMFOCRF, Feature64BitSupport,
                   FeatureSTFIWX, FeatureICBT, FeatureBookE,
                   FeatureISEL, FeatureMFTB]>;
// NXP/Freescale e200 family.  Feature lists follow
// plans/e200/capability-matrix.yaml; the cited manual is the authority for
// each core.  Floating point defaults to soft-float: no e200 core has a
// classic FPU, and the SPE/EFPU2 float ABI is selected by the driver.

// e200z0CORERM Rev. 0: VLE-only Book E v2.0, isel, debug APU (se_rfdi), wait;
// no MMU, caches, timers or SPE (p.23, p.55-61).  e200z0h differs only in
// microarchitecture (BTB, buses, NMI; p.23-24, p.69).
def : ProcessorModel<"e200z0", NoSchedModel,
                     [DirectiveE200, FeatureE200Z0Family, FeatureVLEOnly,
                      FeatureMSYNC, FeatureISEL, FeatureDebugAPU,
                      FeatureWait]>;
def : ProcessorModel<"e200z0h", NoSchedModel,
                     [DirectiveE200, FeatureE200Z0Family, FeatureVLEOnly,
                      FeatureMSYNC, FeatureISEL, FeatureDebugAPU,
                      FeatureWait]>;
// e200z1RM Rev. 0: Book E + VLE v1.01, 32-bit GPRs, 8-entry TLB, DCRs,
// timers, isel, debug APU, wait; no SPE (p.21, p.55-60, p.139).
def : ProcessorModel<"e200z1", NoSchedModel,
                     [DirectiveE200, FeatureE200Z1Family, FeatureVLEISA,
                      FeatureMSYNC, FeatureISEL, FeatureMFTB,
                      FeatureDebugAPU, FeatureWait, FeatureDCR,
                      FeatureBookEMMU]>;
// UM0434 Rev 2 (e200z3): Book E + VLE, 64-bit GPRs, SPE with scalar and
// vector single-precision EFP, 16-entry TLB, DCRs; no wait (p.24, p.108-122).
def : ProcessorModel<"e200z3", NoSchedModel,
                     [DirectiveE200, FeatureE200Z3Family, FeatureVLEISA,
                      FeatureMSYNC, FeatureISEL, FeatureMFTB,
                      FeatureDebugAPU, FeatureDCR, FeatureBookEMMU,
                      FeatureSPEISA]>;
// e200z4RM Rev. 0 (e200z446n3): Book E + VLE, SPE 1.1, EFPU2, machine check
// APU, dnh, wait, volatile context save/restore, enhanced reservations,
// 16-entry TLB, DCRs (p.38, p.44, p.93-115).
def : ProcessorModel<"e200z446n3", NoSchedModel,
                     [DirectiveE200, FeatureE200Z4Family, FeatureVLEISA,
                      FeatureMSYNC, FeatureISEL, FeatureMFTB,
                      FeatureDebugAPU, FeatureMCheckAPU, FeatureWait,
                      FeatureDNH, FeatureVLEVolatileCtx, FeatureDCR,
                      FeatureBookEMMU, FeatureSPEISA, FeatureEFPU2Ext,
                      FeaturePartwordAtomic]>;
// e200z6RM Rev. 0: Book E (VLE not documented), SPE with single-precision
// EFP, 32-entry TLB; no DCRs (p.27-33, p.123-124, p.211).
def : ProcessorModel<"e200z6", NoSchedModel,
                     [DirectiveE200, FeatureE200Z6Family, FeatureMSYNC,
                      FeatureISEL, FeatureMFTB, FeatureDebugAPU,
                      FeatureBookEMMU, FeatureSPEISA]>;
// e200z759n3CRM Rev. 2: as e200z446n3 plus the performance monitor APU
// (p.21-22, p.63-84, Ch.8).
def : ProcessorModel<"e200z759n3", NoSchedModel,
                     [DirectiveE200, FeatureE200Z7Family, FeatureVLEISA,
                      FeatureMSYNC, FeatureISEL, FeatureMFTB,
                      FeatureDebugAPU, FeatureMCheckAPU, FeatureWait,
                      FeatureDNH, FeatureVLEVolatileCtx, FeatureDCR,
                      FeatureBookEMMU, FeatureSPEISA, FeatureEFPU2Ext,
                      FeaturePartwordAtomic, FeaturePerfMon]>;
// e200z760RM Rev. 2: as e200z759n3; its SPE 2.1 extensions are not
// implemented because no encodings are documented (Ch.6, p.274).
def : ProcessorModel<"e200z760n3", NoSchedModel,
                     [DirectiveE200, FeatureE200Z7Family, FeatureVLEISA,
                      FeatureMSYNC, FeatureISEL, FeatureMFTB,
                      FeatureDebugAPU, FeatureMCheckAPU, FeatureWait,
                      FeatureDNH, FeatureVLEVolatileCtx, FeatureDCR,
                      FeatureBookEMMU, FeatureSPEISA, FeatureEFPU2Ext,
                      FeaturePartwordAtomic, FeaturePerfMon]>;
// Family names resolve to the documented implementation.  e200z7 resolves to
// e200z759n3, whose documented features are a subset of e200z760n3's.
def : ProcessorAlias<"e200z4", "e200z446n3">;
def : ProcessorAlias<"e200z7", "e200z759n3">;
def : ProcessorAlias<"e200z759", "e200z759n3">;
def : ProcessorAlias<"e200z760", "e200z760n3">;

def : ProcessorModel<"a2", PPCA2Model,
                  [DirectiveA2, FeatureICBT, FeatureBookE, FeatureMFOCRF,
                   FeatureFCPSGN, FeatureFSqrt, FeatureFRE, FeatureFRES,
                   FeatureFRSQRTE, FeatureFRSQRTES, FeatureRecipPrec,
                   FeatureSTFIWX, FeatureLFIWAX,
                   FeatureFPRND, FeatureFPCVT, FeatureISEL,
                   FeatureSlowPOPCNTD, FeatureCMPB, FeatureLDBRX,
                   Feature64BitSupport /*, Feature64BitRegs */, FeatureMFTB,
                   FeatureISA2_06]>;
def : ProcessorModel<"pwr3", G5Model,
                  [DirectivePwr3, FeatureAltivec,
                   FeatureFRES, FeatureFRSQRTE, FeatureMFOCRF,
                   FeatureSTFIWX, Feature64BitSupport]>;
def : ProcessorModel<"pwr4", G5Model,
                  [DirectivePwr4, FeatureAltivec, FeatureMFOCRF,
                   FeatureFSqrt, FeatureFRES, FeatureFRSQRTE,
                   FeatureSTFIWX, Feature64BitSupport, FeatureMFTB]>;
def : ProcessorModel<"pwr5", G5Model,
                  [DirectivePwr5, FeatureAltivec, FeatureMFOCRF,
                   FeatureFSqrt, FeatureFRE, FeatureFRES,
                   FeatureFRSQRTE, FeatureFRSQRTES,
                   FeatureSTFIWX, Feature64BitSupport,
                   FeatureMFTB, DeprecatedDST]>;
def : ProcessorModel<"pwr5x", G5Model,
                  [DirectivePwr5x, FeatureAltivec, FeatureMFOCRF,
                   FeatureFSqrt, FeatureFRE, FeatureFRES,
                   FeatureFRSQRTE, FeatureFRSQRTES,
                   FeatureSTFIWX, FeatureFPRND, Feature64BitSupport,
                   FeatureMFTB, DeprecatedDST]>;
def : ProcessorModel<"pwr6", G5Model,
                  [DirectivePwr6, FeatureAltivec,
                   FeatureMFOCRF, FeatureFCPSGN, FeatureFSqrt, FeatureFRE,
                   FeatureFRES, FeatureFRSQRTE, FeatureFRSQRTES,
                   FeatureRecipPrec, FeatureSTFIWX, FeatureLFIWAX, FeatureCMPB,
                   FeatureFPRND, Feature64BitSupport /*, Feature64BitRegs */,
                   FeatureMFTB, DeprecatedDST]>;
def : ProcessorModel<"pwr6x", G5Model,
                  [DirectivePwr5x, FeatureAltivec, FeatureMFOCRF,
                   FeatureFCPSGN, FeatureFSqrt, FeatureFRE, FeatureFRES,
                   FeatureFRSQRTE, FeatureFRSQRTES, FeatureRecipPrec,
                   FeatureSTFIWX, FeatureLFIWAX, FeatureCMPB,
                   FeatureFPRND, Feature64BitSupport,
                   FeatureMFTB, DeprecatedDST]>;
def : ProcessorModel<"pwr7", P7Model, ProcessorFeatures.P7Features>;
def : ProcessorModel<"pwr8", P8Model, ProcessorFeatures.P8Features>;
def : ProcessorModel<"pwr9", P9Model, ProcessorFeatures.P9Features>;
def : ProcessorModel<"pwr10", P10Model, ProcessorFeatures.P10Features>;
def : ProcessorModel<"pwr11", P10Model, ProcessorFeatures.P11Features>;
// No scheduler model for future CPU.
def : ProcessorModel<"future", NoSchedModel,
                  ProcessorFeatures.FutureFeatures>;
def : Processor<"ppc", G3Itineraries, [Directive32, FeatureHardFloat,
                                       FeatureMFTB]>;
def : Processor<"ppc32", G3Itineraries, [Directive32, FeatureHardFloat,
                                         FeatureMFTB]>;
def : ProcessorModel<"ppc64", G5Model,
                  [Directive64, FeatureAltivec,
                   FeatureMFOCRF, FeatureFSqrt, FeatureFRES,
                   FeatureFRSQRTE, FeatureSTFIWX,
                   Feature64BitSupport /*, Feature64BitRegs */,
                   FeatureMFTB]>;
def : ProcessorModel<"ppc64le", P8Model, ProcessorFeatures.P8Features>;
