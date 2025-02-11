/*
 *  Copyright (c) 2020-2022 Thakee Nathees
 *  Copyright (c) 2021-2022 Pocketlang Contributors
 *  Distributed Under The MIT License
 */

#ifndef PK_AMALGAMATED
#include "libs.h"
#endif

// Standard libraries.

void registerModuleMath(PKVM* vm);
void registerModuleTypes(PKVM* vm);
void registerModuleTime(PKVM* vm);
void registerModuleIO(PKVM* vm);
void registerModulePath(PKVM* vm);
void registerModuleOS(PKVM* vm);
void registerModuleJson(PKVM* vm);
void registerModuleRe(PKVM* vm);
void registerModuleAlgorithm(PKVM* vm);
void registerModuleRandom(PKVM* vm);

void cleanupModuleTerm(PKVM* vm);

// Registers the modules.
void registerLibs(PKVM* vm) {
  registerModuleMath(vm);
  registerModuleTypes(vm);
  registerModuleTime(vm);
  registerModuleIO(vm);
  registerModulePath(vm);
  registerModuleOS(vm);
  registerModuleJson(vm);
  registerModuleRe(vm);
  registerModuleAlgorithm(vm);
  registerModuleRandom(vm);
}

// Cleanup the modules.
void cleanupLibs(PKVM* vm) {
}
