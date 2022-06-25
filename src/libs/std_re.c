/*
 *  Copyright (c) 2020-2022 Thakee Nathees
 *  Copyright (c) 2021-2022 Pocketlang Contributors
 *  Distributed Under The MIT License
 */

#ifndef PK_AMALGAMATED
#include "libs.h"
#include "../core/value.h"
#include "../core/vm.h"
#endif

#include "thirdparty/tinyre/lib/platform.h"
#include "thirdparty/tinyre/lib/utf8_lite.h"
#include "thirdparty/tinyre/tinyre.h"
#include "thirdparty/tinyre/tlexer.h"
#include "thirdparty/tinyre/tparser.h"
#include "thirdparty/tinyre/tvm.h"

#include "thirdparty/tinyre/lib/platform.c"
#include "thirdparty/tinyre/lib/utf8_lite.c"
#include "thirdparty/tinyre/tinyre.c"
#include "thirdparty/tinyre/tlexer.c"
#include "thirdparty/tinyre/tparser.c"
#include "thirdparty/tinyre/tvm.c"

typedef struct {
  tre_Pattern* tp;
} Pattern;

typedef struct {
  tre_Match* tm;
} Match;

void* _patternNew(PKVM* vm) {
  Pattern* pattern = pkRealloc(vm, NULL, sizeof(Pattern));
  ASSERT(pattern != NULL, "pkRealloc failed.");
  pattern->tp = NULL;
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

  int argc = pkGetArgc(vm);
  if (!pkCheckArgcRange(vm, argc, 1, 2)) return;

  const char* pat;
  if (!pkValidateSlotString(vm, 1, &pat, NULL)) return;

  if (!pkImportModule(vm, "re", 0)) return;           // slots[0] = re
  if (!pkGetAttribute(vm, 0, "Pattern", 0)) return;   // slots[0] = Pattern
  if (!pkNewInstance(vm, 0, 0, 0, 0)) return;         // slots[0] = Pattern()

  Pattern* pattern = (Pattern*) pkGetSlotNativeInstance(vm, 0);
  ASSERT(pattern != NULL, OOPS);

  int err_code;
  pattern->tp = tre_compile(pat, FLAG_DOTALL, &err_code);
  if (pattern->tp) {
    pkSetSlotBool(vm, 1, true);
    pkSetAttribute(vm, 0, "ok", 1);
    pkSetSlotNull(vm, 1);
    pkSetAttribute(vm, 0, "error", 1);
  } else {
    pkSetSlotBool(vm, 1, false);
    pkSetAttribute(vm, 0, "ok", 1);
    pkSetSlotString(vm, 1, tre_err(err_code));
    pkSetAttribute(vm, 0, "error", 1);
  }
}

DEF(_patternMatch,
  "re.Pattern.match(input:String)",
  "Initialize a Pattern instance.") {

  const char* input;
  if (!pkValidateSlotString(vm, 1, &input, NULL)) return;

  pkPlaceSelf(vm, 1);
  Pattern* pattern = pkGetSlotNativeInstance(vm, 1);
  ASSERT(pattern != NULL, OOPS);

  if (!pattern->tp) {
    pkSetRuntimeError(vm, "Invalid pattern instance.");
    return;
  }

  tre_Match* tm = tre_match(pattern->tp, input, 4096);
  if (tm->groups) {
    if (!pkImportModule(vm, "re", 0)) return;           // slots[0] = re
    if (!pkGetAttribute(vm, 0, "Match", 0)) return;     // slots[0] = Match
    if (!pkNewInstance(vm, 0, 0, 0, 0)) return;         // slots[0] = Match()

    Match* match = (Match*) pkGetSlotNativeInstance(vm, 0);
    ASSERT(match != NULL, OOPS);
    match->tm = tm;

    pkSetSlotNumber(vm, 1, (double) tm->groupnum);
    pkSetAttribute(vm, 0, "length", 1);

  } else { // return null if there is no match
    pkSetSlotNull(vm, 0);
  }
}

static int _ucs4_to_utf8(char buffer[16], uint32_t code) {
  const char abPrefix[] = {0, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC};
  const int adwCodeUp[] = {
      0x80,           // U+00000000 ～ U+0000007F
      0x800,          // U+00000080 ～ U+000007FF
      0x10000,        // U+00000800 ～ U+0000FFFF
      0x200000,       // U+00010000 ～ U+001FFFFF
      0x4000000,      // U+00200000 ～ U+03FFFFFF
      0x80000000      // U+04000000 ～ U+7FFFFFFF
  };

  int i, ilen;

  ilen = sizeof(adwCodeUp) / sizeof(uint32_t);
  for(i = 0; i < ilen; i++) {
      if( code < adwCodeUp[i] ) break;
  }

  if (i == ilen) return 0;

  ilen = i + 1;
  for( ; i > 0; i-- ) {
      buffer[i] = (char)((code & 0x3F) | 0x80);
      code >>= 6;
  }

  buffer[0] = (char)(code | abPrefix[ilen - 1]);
  return ilen;
}

DEF(_matchGroup,
  "re.Match.group(index:Number) -> String",
  "Initialize a Pattern instance.") {

  int32_t index;
  if (!pkValidateSlotInteger(vm, 1, &index)) return;

  pkPlaceSelf(vm, 1);
  Match* match = (Match*) pkGetSlotNativeInstance(vm, 1);
  ASSERT(match != NULL, OOPS);

  if (index < 0 || index >= match->tm->groupnum) {
    pkSetRuntimeError(vm, "Index out of bound");
    return;
  }

  char buffer[16];
  pkByteBuffer buff;
  pkByteBufferInit(&buff);

  for (int i = match->tm->groups[index].head; i < match->tm->groups[index].tail; i++) {
    int len = _ucs4_to_utf8(buffer, match->tm->str[i]);
    if (len == 0) break;
    pkByteBufferAddString(&buff, vm, buffer, len);
  }

  Var str = VAR_OBJ(newStringLength(vm, (const char*)buff.data, buff.count));
  pkByteBufferClear(&buff, vm);

  vm->fiber->ret[0] = str;
}

DEF(_matchName,
  "re.Match.Name(index:Number) -> String",
  "Initialize a Pattern instance.") {

  int32_t index;
  if (!pkValidateSlotInteger(vm, 1, &index)) return;

  pkPlaceSelf(vm, 1);
  Match* match = (Match*) pkGetSlotNativeInstance(vm, 1);
  ASSERT(match != NULL, OOPS);

  if (index < 0 || index >= match->tm->groupnum) {
    pkSetRuntimeError(vm, "Index out of bound");
    return;
  }

  char buffer[16];
  pkByteBuffer buff;
  pkByteBufferInit(&buff);

  for (int i = 0; i < match->tm->groups[index].name_len; i++) {
    int len = _ucs4_to_utf8(buffer, match->tm->groups[index].name[i]);
    if (len == 0) break;
    pkByteBufferAddString(&buff, vm, buffer, len);
  }

  Var str = VAR_OBJ(newStringLength(vm, (const char*)buff.data, buff.count));
  pkByteBufferClear(&buff, vm);

  vm->fiber->ret[0] = str;
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

  REGISTER_FN(re, "compile", _reCompile, -1);
  // REGISTER_FN(re, "match", _reMatch, 2);

  PkHandle* cls_pattern = pkNewClass(vm, "Pattern", NULL, re,
    _patternNew, _patternDelete, NULL);

  ADD_METHOD(cls_pattern, "_init", _patternInit, 0);
  ADD_METHOD(cls_pattern, "match", _patternMatch, 1);

  PkHandle* cls_match = pkNewClass(vm, "Match", NULL, re,
    _matchNew, _matchDelete, NULL);

  ADD_METHOD(cls_match, "_init", _matchInit, 0);
  ADD_METHOD(cls_match, "group", _matchGroup, 1);
  ADD_METHOD(cls_match, "name", _matchName, 1);

  pkReleaseHandle(vm, cls_pattern);
  pkReleaseHandle(vm, cls_match);

  pkRegisterModule(vm, re);
  pkReleaseHandle(vm, re);
}

