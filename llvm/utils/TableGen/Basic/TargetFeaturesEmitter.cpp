//===- TargetFeaturesEmitter.cpp - Generate CPU Target feature ----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//  This tablegen backend exports cpu target features
//  and cpu sub-type.
//
//===----------------------------------------------------------------------===//

#include "TargetFeaturesEmitter.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/TableGen/CodeGenHelpers.h"
#include "llvm/TableGen/Error.h"
#include "llvm/TableGen/TableGenBackend.h"
#include "llvm/TargetParser/SubtargetFeature.h"

using namespace llvm;

using FeatureMapTy = DenseMap<const Record *, unsigned>;
using ConstRecVec = std::vector<const Record *>;

TargetFeaturesEmitter::TargetFeaturesEmitter(const RecordKeeper &R)
    : Records(R) {
  ArrayRef<const Record *> Targets = Records.getAllDerivedDefinitions("Target");
  if (Targets.size() == 0)
    PrintFatalError("No 'Target' subclasses defined!");
  if (Targets.size() != 1)
    PrintFatalError("Multiple subclasses of Target defined!");
  Target = Targets[0]->getName();
}

FeatureMapTy TargetFeaturesEmitter::enumeration(raw_ostream &OS) {
  ArrayRef<const Record *> DefList =
      Records.getAllDerivedDefinitions("SubtargetFeature");

  unsigned N = DefList.size();
  if (N == 0)
    return FeatureMapTy();

  if (N + 1 > MAX_SUBTARGET_FEATURES)
    PrintFatalError(
        "Too many subtarget features! Bump MAX_SUBTARGET_FEATURES.");

  NamespaceEmitter NS(OS, Target);

  OS << "enum {\n";

  FeatureMapTy FeatureMap;
  for (unsigned I = 0; I < N; ++I) {
    const Record *Def = DefList[I];
    // Print the Feature Name.
    OS << "  " << Def->getName() << " = " << I << ",\n";

    FeatureMap[Def] = I;
  }

  OS << "  " << "NumSubtargetFeatures = " << N << "\n";

  // Close enumeration.
  OS << "};\n";
  return FeatureMap;
}

void TargetFeaturesEmitter::printFeatureMask(
    raw_ostream &OS, ArrayRef<const Record *> FeatureList,
    const FeatureMapTy &FeatureMap) {
  std::array<uint64_t, MAX_SUBTARGET_WORDS> Mask = {};
  for (const Record *Feature : FeatureList) {
    unsigned Bit = FeatureMap.lookup(Feature);
    Mask[Bit / 64] |= 1ULL << (Bit % 64);
  }

  OS << "{ { { ";
  for (unsigned I = 0; I != Mask.size(); ++I) {
    OS << "0x";
    OS.write_hex(Mask[I]);
    OS << "ULL, ";
  }
  OS << "} } }";
}

void TargetFeaturesEmitter::printFeatureKeyValues(
    raw_ostream &OS, const FeatureMapTy &FeatureMap) {
  std::vector<const Record *> FeatureList =
      Records.getAllDerivedDefinitions("SubtargetFeature");

  // Remove features with empty name.
  llvm::erase_if(FeatureList, [](const Record *Rec) {
    return Rec->getValueAsString("Name").empty();
  });

  if (FeatureList.empty())
    return;

  llvm::sort(FeatureList, LessRecordFieldName());

  // Begin feature table.
  OS << "// Sorted (by key) array of values for CPU features.\n"
     << "extern const llvm::BasicSubtargetFeatureKV " << "Basic" << Target
     << "FeatureKV[] = {\n";

  for (const Record *Feature : FeatureList) {
    StringRef Name = Feature->getName();
    StringRef ValueName = Feature->getValueAsString("Name");

    OS << "  { " << "\"" << ValueName << "\", " << Target << "::" << Name
       << ", ";

    ConstRecVec ImpliesList = Feature->getValueAsListOfDefs("Implies");

    printFeatureMask(OS, ImpliesList, FeatureMap);

    OS << " },\n";
  }

  // End feature table.
  OS << "};\n";
}

std::vector<std::pair<StringRef, const Record *>>
TargetFeaturesEmitter::getProcessorAliases() const {
  StringMap<const Record *> Processors;
  for (const Record *Processor : Records.getAllDerivedDefinitions("Processor"))
    Processors[Processor->getValueAsString("Name")] = Processor;

  std::vector<std::pair<StringRef, const Record *>> Aliases;
  StringSet<> AliasNames;
  for (const Record *Rec :
       Records.getAllDerivedDefinitionsIfDefined("ProcessorAlias")) {
    StringRef Name = Rec->getValueAsString("Name");
    StringRef Alias = Rec->getValueAsString("Alias");
    auto It = Processors.find(Alias);
    if (It == Processors.end())
      PrintFatalError(Rec, "Alias '" + Name +
                               "' references a non-existent Processor '" +
                               Alias + "'");
    if (Processors.contains(Name))
      PrintFatalError(Rec,
                      "Alias '" + Name + "' duplicates an existing Processor");
    if (!AliasNames.insert(Name).second)
      PrintFatalError(Rec, "Alias '" + Name + "' duplicates an existing alias");
    Aliases.emplace_back(Name, It->second);
  }
  llvm::sort(Aliases, llvm::less_first());
  return Aliases;
}

void TargetFeaturesEmitter::printCPUKeyValues(raw_ostream &OS,
                                              const FeatureMapTy &FeatureMap) {
  // Gather processors and aliases; an alias carries the features of the
  // processor it resolves to.
  std::vector<std::pair<StringRef, const Record *>> Entries;
  for (const Record *Processor : Records.getAllDerivedDefinitions("Processor"))
    Entries.emplace_back(Processor->getValueAsString("Name"), Processor);
  for (const auto &Alias : getProcessorAliases())
    Entries.push_back(Alias);
  llvm::sort(Entries, llvm::less_first());

  // Begin processor table.
  OS << "// Sorted (by key) array of values for CPU subtype.\n"
     << "extern const llvm::BasicSubtargetSubTypeKV " << "Basic" << Target
     << "SubTypeKV[] = {\n";

  for (const auto &[Name, Processor] : Entries) {
    ConstRecVec FeatureList = Processor->getValueAsListOfDefs("Features");

    OS << " { " << "\"" << Name << "\", ";

    printFeatureMask(OS, FeatureList, FeatureMap);
    OS << " },\n";
  }

  // End processor table.
  OS << "};\n";
}

void TargetFeaturesEmitter::printProcessorAliases(raw_ostream &OS) {
  std::vector<std::pair<StringRef, const Record *>> Aliases =
      getProcessorAliases();
  if (Aliases.empty())
    return;

  OS << "// Sorted (by alias) array of processor aliases.\n"
     << "extern const llvm::BasicProcessorAlias " << "Basic" << Target
     << "ProcessorAliases[] = {\n";
  for (const auto &[Name, Processor] : Aliases)
    OS << "  { \"" << Name << "\", \"" << Processor->getValueAsString("Name")
       << "\" },\n";
  OS << "};\n";
}

void TargetFeaturesEmitter::printFeatureDescriptions(raw_ostream &OS) {
  std::vector<const Record *> FeatureList =
      Records.getAllDerivedDefinitions("SubtargetFeature");
  llvm::erase_if(FeatureList, [](const Record *Rec) {
    return Rec->getValueAsString("Name").empty();
  });
  if (FeatureList.empty())
    return;
  llvm::sort(FeatureList, LessRecordFieldName());

  OS << "// Sorted (by key) array of feature descriptions.\n"
     << "extern const llvm::BasicSubtargetFeatureDesc " << "Basic" << Target
     << "FeatureDescs[] = {\n";
  for (const Record *Feature : FeatureList) {
    OS << "  { \"" << Feature->getValueAsString("Name") << "\", \"";
    OS.write_escaped(Feature->getValueAsString("Desc"));
    OS << "\" },\n";
  }
  OS << "};\n";
}

void TargetFeaturesEmitter::run(raw_ostream &OS) {
  OS << "// Autogenerated by TargetFeatureEmitter.cpp\n\n";

  FeatureMapTy FeatureMap;
  {
    IfDefEmitter IfDef(OS, "GET_SUBTARGETFEATURES_ENUM");
    NamespaceEmitter NS(OS, "llvm");
    FeatureMap = enumeration(OS);
  }

  {
    IfDefEmitter IfDef(OS, "GET_SUBTARGETFEATURES_KV");
    NamespaceEmitter NS(OS, "llvm");

    printFeatureKeyValues(OS, FeatureMap);
    OS << "\n";

    printCPUKeyValues(OS, FeatureMap);
    OS << "\n";
  }

  {
    IfDefEmitter IfDef(OS, "GET_SUBTARGETFEATURES_ALIASES");
    NamespaceEmitter NS(OS, "llvm");
    printProcessorAliases(OS);
  }

  {
    IfDefEmitter IfDef(OS, "GET_SUBTARGETFEATURES_DESCS");
    NamespaceEmitter NS(OS, "llvm");
    printFeatureDescriptions(OS);
  }
}

static TableGen::Emitter::OptClass<TargetFeaturesEmitter>
    X("gen-target-features", "Generate subtarget enumerations");
