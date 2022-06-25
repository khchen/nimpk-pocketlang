/*
 *  Copyright (c) 2020-2022 Thakee Nathees
 *  Copyright (c) 2021-2022 Pocketlang Contributors
 *  Distributed Under The MIT License
 */

#ifndef PK_AMALGAMATED
#include "libs.h"
#endif

#include "thirdparty/tinyre/lib/platform.h" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/lib/utf8_lite.h" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/tinyre.h" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/tlexer.h" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/tparser.h" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/tvm.h" //<< AMALG_INLINE >>

#include "thirdparty/tinyre/lib/platform.c" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/lib/utf8_lite.c" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/tinyre.c" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/tlexer.c" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/tparser.c" //<< AMALG_INLINE >>
#include "thirdparty/tinyre/tvm.c" //<< AMALG_INLINE >>

typedef struct {
  tre_Pattern* tp;
  int error_code;
} Pattern;

typedef struct {
  tre_Match* tm;
} Match;

void* _patternNew(PKVM* vm) {
  Pattern* pattern = pkRealloc(vm, NULL, sizeof(Pattern));
  ASSERT(pattern != NULL, "pkRealloc failed.");
  pattern->tp = NULL;
  pattern->error_code = 0;
  return pattern;
}

void _patternDelete(PKVM* vm, void* ptr) {
  Pattern* pattern = (Pattern*)ptr; 
  if (pattern->tp) {
    tre_pattern_free(pattern->tp);
    pattern->tp = NULL;
  }
  pkRealloc(vm, ptr, 0);
}

void* _matchNew(PKVM* vm) {
  Match* match = pkRealloc(vm, NULL, sizeof(Match));
  ASSERT(match != NULL, "pkRealloc failed.");
  match->tm = NULL;
  return match;
}

void _matchDelete(PKVM* vm, void* ptr) {
  Match* match = (Match*)ptr; 
  if (match->tm) {
    tre_match_free(match->tm);
    match->tm = NULL;
  }
  pkRealloc(vm, ptr, 0);
}

DEF(_patternInit,
  "re.Pattern._init()",
  "Initialize a Pattern instance.") {
  pkReserveSlots(vm, 2);
  pkPlaceSelf(vm, 0);
  pkSetSlotBool(vm, 1, false);
  pkSetAttribute(vm, 0, "ok", 1);
  pkSetSlotNull(vm, 1);
  pkSetAttribute(vm, 0, "error", 1);
}

DEF(_matchInit,
  "re.Match._init()",
  "Initialize a Match instance.") {
  pkReserveSlots(vm, 2);
  pkPlaceSelf(vm, 0);
  pkSetSlotBool(vm, 1, false);
  pkSetAttribute(vm, 0, "ok", 1);
  pkSetSlotNull(vm, 1);
  pkSetAttribute(vm, 0, "error", 1);
}

DEF(_reCompile,
  "compile(pattern:String [, flag:Number]): Pattern",
  "Compile regex pattern.") {

  if (!pkImportModule(vm, "re", 0)) return;           // slots[0] = re
  if (!pkGetAttribute(vm, 0, "Pattern", 0)) return;   // slots[0] = Pattern
  if (!pkNewInstance(vm, 0, 0, 0, 0)) return;         // slots[0] = Pattern()

  Pattern* pattern = (Pattern*) pkGetSlotNativeInstance(vm, 0);
  if (pattern) {
    pattern->tp = tre_compile("1(2)[3]", FLAG_DOTALL, &pattern->error_code);
    if (pattern->tp) {
      pattern->error_code = 0;
    }
  }
}

DEF(_reMatch,
  "match(pattern:String, input:String): Match",
  "Return a corresponding match object.") {

  if (!pkImportModule(vm, "re", 0)) return;           // slots[0] = re
  if (!pkGetAttribute(vm, 0, "Match", 0)) return;     // slots[0] = Match
  if (!pkNewInstance(vm, 0, 0, 0, 0)) return;         // slots[0] = Match()

  int err_code;
  tre_Pattern* tp = tre_compile("1(2)[3]", FLAG_DOTALL, &err_code);
  if (tp) {
    tre_Match* tm = tre_match(tp, "123", 5000);
    if (tm->groups) {
      printf("got some matchec\n");


      Match* match = (Match*) pkGetSlotNativeInstance(vm, 0);
      if (match) {
        match->tm = tm;
      }
    }
    tre_pattern_free(tp);
  }


  // pkReserveSlots(vm, 10);
  // if (!pkImportModule(vm, "re", 0)) return;           // slots[0] = re
  // if (!pkGetAttribute(vm, 0, "Pattern", 0)) return;   // slots[0] = Pattern

  // pkGetClass(vm, 1, 0);    
  // bool isPattern = false;

  // if (pkIsSlotInstanceOf(vm, 1, 0, &isPattern) && isPattern) {
  //   printf("yes it is pattern\n");
  // }


  // Pattern* pattern = (Pattern*) pkGetSlotNativeInstance(vm, 0);
  // if (pattern) {
  //   pattern->tp = tre_compile("1(2)[3]", FLAG_DOTALL, &pattern->error_code);
  //   if (pattern->tp) {
  //     pattern->error_code = 0;
  //   }
  // }
}

/*****************************************************************************/
/* MODULE REGISTER                                                           */
/*****************************************************************************/

void registerModuleRe(PKVM* vm) {
  PkHandle* re = pkNewModule(vm, "re");

  pkReserveSlots(vm, 2);
  pkSetSlotHandle(vm, 0, re);
  pkSetSlotNumber(vm, 1, FLAG_IGNORECASE);
  pkSetAttribute(vm, 0, "I", 1);
  pkSetAttribute(vm, 0, "IGNORECASE", 1);
  pkSetSlotNumber(vm, 1, FLAG_MULTILINE);
  pkSetAttribute(vm, 0, "M", 1);
  pkSetAttribute(vm, 0, "MULTILINE", 1);
  pkSetSlotNumber(vm, 1, FLAG_DOTALL);
  pkSetAttribute(vm, 0, "S", 1);
  pkSetAttribute(vm, 0, "DOTALL", 1);

  REGISTER_FN(re, "compile", _reCompile, 0);
  REGISTER_FN(re, "match", _reMatch, 2);

  PkHandle* cls_pattern = pkNewClass(vm, "Pattern", NULL, re,
    _patternNew, _patternDelete, NULL);

  PkHandle* cls_match = pkNewClass(vm, "Match", NULL, re,
    _matchNew, _matchDelete, NULL);

  ADD_METHOD(cls_pattern, "_init", _patternInit, 0);
  ADD_METHOD(cls_match, "_init", _matchInit, 0);

  pkReleaseHandle(vm, cls_pattern);
  pkReleaseHandle(vm, cls_match);

  pkRegisterModule(vm, re);
  pkReleaseHandle(vm, re);
}

