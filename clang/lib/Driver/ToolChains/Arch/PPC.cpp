//===--- PPC.cpp - PPC Helpers for Tools ------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "PPC.h"
#include "clang/Driver/CommonArgs.h"
#include "clang/Driver/Driver.h"
#include "clang/Options/Options.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/Option/ArgList.h"
#include "llvm/TargetParser/Host.h"
#include "llvm/TargetParser/PPCTargetParser.h"

using namespace clang::driver;
using namespace clang::driver::tools;
using namespace clang;
using namespace llvm::opt;

const char *ppc::getPPCAsmModeForCPU(StringRef Name) {
  return llvm::StringSwitch<const char *>(Name)
      .Case("pwr7", "-mpower7")
      .Case("power7", "-mpower7")
      .Case("pwr8", "-mpower8")
      .Case("power8", "-mpower8")
      .Case("ppc64le", "-mpower8")
      .Case("pwr9", "-mpower9")
      .Case("power9", "-mpower9")
      .Case("pwr10", "-mpower10")
      .Case("power10", "-mpower10")
      .Case("pwr11", "-mpower11")
      .Case("power11", "-mpower11")
      .Default("-many");
}

/// Return the default target features of the selected CPU.
static std::optional<llvm::StringMap<bool>>
getCPUFeatures(const Driver &D, const llvm::Triple &Triple,
               const ArgList &Args) {
  return llvm::PPC::getPPCDefaultTargetFeatures(Triple,
                                                getCPUName(D, Args, Triple));
}

bool ppc::addE200AssemblerArgs(const Driver &D, const llvm::Triple &Triple,
                               const ArgList &Args, ArgStringList &CmdArgs) {
  std::optional<llvm::StringMap<bool>> CPUFeatures =
      getCPUFeatures(D, Triple, Args);
  if (!CPUFeatures || !CPUFeatures->lookup("e200"))
    return false;
  bool VLE = Args.hasFlag(options::OPT_mvle, options::OPT_mno_vle,
                          CPUFeatures->lookup("vle"));
  if (VLE) {
    // NXP powerpc-eabivle GCC passes "-mvle", plus "-me200z4" for e200z4.
    CmdArgs.push_back("-mvle");
    if (CPUFeatures->lookup("e200z4-family"))
      CmdArgs.push_back("-me200z4");
  } else {
    // GNU as 2.28 accepts isel, SPE/EFS and the Book E extensions used by
    // e200 with -me500x2; "-me200z4 -mno-vle" rejects isel.
    CmdArgs.push_back("-me500x2");
  }
  return true;
}

void ppc::getPPCTargetFeatures(const Driver &D, const llvm::Triple &Triple,
                               const ArgList &Args,
                               std::vector<StringRef> &Features) {
  if (Triple.getSubArch() == llvm::Triple::PPCSubArch_spe)
    Features.push_back("+spe");

  handleTargetFeaturesGroup(D, Triple, Args, Features,
                            options::OPT_m_ppc_Features_Group);

  if (Arg *A = Args.getLastArg(options::OPT_mspe2, options::OPT_mlsp))
    D.Diag(diag::err_drv_ppc_undocumented_extension)
        << A->getAsString(Args)
        << (A->getOption().matches(options::OPT_mspe2) ? "SPE2" : "LSP");

  ppc::FloatABI FloatABI = ppc::getPPCFloatABI(D, Triple, Args);
  if (FloatABI == ppc::FloatABI::Soft)
    Features.push_back("-hard-float");
  else if (Args.hasArg(options::OPT_mhard_float, options::OPT_mfloat_abi_EQ))
    // CPUs without hard-float in their defaults (e200) need the explicit
    // request to select hardware floating point.
    Features.push_back("+hard-float");

  ppc::ReadGOTPtrMode ReadGOT = ppc::getPPCReadGOTPtrMode(D, Triple, Args);
  if (ReadGOT == ppc::ReadGOTPtrMode::SecurePlt)
    Features.push_back("+secure-plt");

  bool UseSeparateSections = isUseSeparateSections(Triple);
  bool HasDefaultDataSections = Triple.isOSBinFormatXCOFF();
  if (Args.hasArg(options::OPT_maix_small_local_exec_tls) ||
      Args.hasArg(options::OPT_maix_small_local_dynamic_tls)) {
    if (!Triple.isOSAIX() || !Triple.isArch64Bit())
      D.Diag(diag::err_opt_not_valid_on_target)
          << "-maix-small-local-[exec|dynamic]-tls";

    // The -maix-small-local-[exec|dynamic]-tls option should only be used with
    // -fdata-sections, as having data sections turned off with this option
    // is not ideal for performance. Moreover, the
    // small-local-[exec|dynamic]-tls region is a limited resource, and should
    // not be used for variables that may be replaced.
    if (!Args.hasFlag(options::OPT_fdata_sections,
                      options::OPT_fno_data_sections,
                      UseSeparateSections || HasDefaultDataSections))
      D.Diag(diag::err_drv_argument_only_allowed_with)
          << "-maix-small-local-[exec|dynamic]-tls" << "-fdata-sections";
  }

  if (Args.hasArg(options::OPT_maix_shared_lib_tls_model_opt) &&
      !(Triple.isOSAIX() && Triple.isArch64Bit()))
    D.Diag(diag::err_opt_not_valid_on_target)
        << "-maix-shared-lib-tls-model-opt";

  // The integrated assembler counts as a "modern AIX assembler" for the
  // purposes of the modern-aix-as.
  if (Args.hasFlag(options::OPT_fintegrated_as, options::OPT_fno_integrated_as,
                   true) &&
      Triple.isOSAIX())
    Features.push_back("+modern-aix-as");

  if (Arg *A = Args.getLastArg(options::OPT_mnoaix_use_ptrgl,
                               options::OPT_maix_use_ptrgl)) {
    if (!Triple.isOSAIX())
      D.Diag(diag::err_drv_unsupported_opt_for_target)
          << A->getAsString(Args) << Triple.str();
    else if (A->getOption().matches(options::OPT_maix_use_ptrgl))
      Features.push_back("+use-ptrgl-helper");
  }
}

ppc::ReadGOTPtrMode ppc::getPPCReadGOTPtrMode(const Driver &D, const llvm::Triple &Triple,
                                              const ArgList &Args) {
  if (Args.getLastArg(options::OPT_msecure_plt))
    return ppc::ReadGOTPtrMode::SecurePlt;
  if (Triple.isPPC32SecurePlt())
    return ppc::ReadGOTPtrMode::SecurePlt;
  else
    return ppc::ReadGOTPtrMode::Bss;
}

ppc::FloatABI ppc::getPPCFloatABI(const Driver &D, const llvm::Triple &Triple,
                                  const ArgList &Args) {
  ppc::FloatABI ABI = ppc::FloatABI::Invalid;
  if (Arg *A =
          Args.getLastArg(options::OPT_msoft_float, options::OPT_mhard_float,
                          options::OPT_mfloat_abi_EQ)) {
    if (A->getOption().matches(options::OPT_msoft_float))
      ABI = ppc::FloatABI::Soft;
    else if (A->getOption().matches(options::OPT_mhard_float))
      ABI = ppc::FloatABI::Hard;
    else {
      ABI = llvm::StringSwitch<ppc::FloatABI>(A->getValue())
                .Case("soft", ppc::FloatABI::Soft)
                .Case("hard", ppc::FloatABI::Hard)
                .Default(ppc::FloatABI::Invalid);
      if (ABI == ppc::FloatABI::Invalid && !StringRef(A->getValue()).empty()) {
        D.Diag(clang::diag::err_drv_invalid_mfloat_abi) << A->getAsString(Args);
        ABI = ppc::FloatABI::Hard;
      }
    }
  }

  // If unspecified, choose the default based on the platform.  CPUs with
  // strict ISA categories and no hard-float default (e200, which has no
  // classic FPU) default to soft float, as NXP's powerpc-eabivle GCC does.
  if (ABI == ppc::FloatABI::Invalid) {
    std::optional<llvm::StringMap<bool>> CPUFeatures =
        getCPUFeatures(D, Triple, Args);
    bool WantsSPE =
        Args.hasFlag(options::OPT_mspe, options::OPT_mno_spe, false) ||
        Args.hasArg(options::OPT_mefpu2);
    if (CPUFeatures && CPUFeatures->lookup("strict-isa-categories") &&
        !CPUFeatures->lookup("hard-float") && !WantsSPE)
      ABI = ppc::FloatABI::Soft;
    else
      ABI = ppc::FloatABI::Hard;
  }

  return ABI;
}

bool ppc::hasPPCAbiArg(const ArgList &Args, const char *Value) {
  Arg *A = Args.getLastArg(options::OPT_mabi_EQ);
  return A && (A->getValue() == StringRef(Value));
}
