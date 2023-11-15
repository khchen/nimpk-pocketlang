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

#include "thirdparty/pikevm/re.c"

#define RE_IGNORECASE 1
#define RE_GLOBAL 2
#define RE_UTF8 4

static RE* _re_init(PKVM* vm, const char** input, uint32_t* len,
    int flag_argc, int* global) {

  const char *pattern; uint32_t pattern_len;
  if (!pkValidateSlotString(vm, 1, &pattern, &pattern_len)) return NULL;
  if (!pkValidateSlotString(vm, 2, input, len)) return NULL;

  int32_t flags = 0;
  if (pkGetArgc(vm) >= flag_argc) {
    if (!pkValidateSlotInteger(vm, flag_argc, &flags)) return NULL;
  }

  if (global) *global = (flags & RE_GLOBAL) == RE_GLOBAL;
  int insensitive = (flags & RE_IGNORECASE) == RE_IGNORECASE;
  int utf8 = (flags & RE_UTF8) == RE_UTF8;

  RE* re = re_compile(pattern, insensitive, utf8);
  if (!re) {
    pkSetRuntimeError(vm, "Cannot compile the regex pattern.");
    return NULL;
  }

  return re;
}

static void _re_match(PKVM* vm, RE* re, const char *input, uint32_t len,
    bool global, bool range, bool includeSub) {

  pkNewList(vm, 0);
  const char *ptr = input;
  uint32_t len0 = len;
  const char *lastMatch1 = NULL;

  do {
    const char** matches = re_match(re, ptr, len);
    if (!matches) break;

    for (int i = 0; i < re_max_matches(re); i += 2) {
      if (i == 0 && lastMatch1 == matches[1] && ptr == lastMatch1) {
        // match same anchor again, avoid to yield the same slice twice.
        continue;
      }

      if (matches[i] && matches[i + 1]) {
        if (range) pkNewRange(vm, 1, matches[i] - input, matches[i + 1] - input);
        else pkSetSlotStringLength(vm, 1, matches[i], matches[i + 1] - matches[i]);
        pkListInsert(vm, 0, -1, 1);
      } else {
        if (range) pkSetSlotNull(vm, 1);
        else pkSetSlotStringLength(vm, 1, ptr, 0);
        pkListInsert(vm, 0, -1, 1);
      }
      if (!includeSub) break;
    }

    // zero length captures, advance one character instead of break
    if (ptr == matches[1]) {
      int uclen = re_uc_len(re, ptr);
      len -= uclen;
      ptr += uclen;
    } else {
      len -= matches[1] - ptr;
      ptr = matches[1]; // point to last matched char
    }

    lastMatch1 = matches[1];
  } while (global && ptr <= input + len0);
}

DEF(_reMatch,
  "re.match(pattern:String, input:String[, flag:Number]) -> List",
  "Perform a regular expression match and return a list of matches.\n\n"
  "Supported patterns:\n"
  "  ^          Match beginning of a buffer\n"
  "  $          Match end of a buffer\n"
  "  (...)      Grouping and substring capturing\n"
  "  (?:...)    Non-capture grouping\n"
  "  \\s         Match whitespace [ \\t\\n\\r\\f\\v]\n"
  "  \\S         Match non-whitespace [^ \\t\\n\\r\\f\\v]\n"
  "  \\w         Match alphanumeric [a-zA-Z0-9_]\n"
  "  \\W         Match non-alphanumeric [^a-zA-Z0-9_]\n"
  "  \\d         Match decimal digit [0-9]\n"
  "  \\D         Match non-decimal digit [^0-9]\n"
  "  \\n         Match new line character\n"
  "  \\r         Match line feed character\n"
  "  \\f         Match form feed character\n"
  "  \\v         Match vertical tab character\n"
  "  \\t         Match horizontal tab character\n"
  "  \\b         Match backspace character\n"
  "  +          Match one or more times (greedy)\n"
  "  +?         Match one or more times (non-greedy)\n"
  "  *          Match zero or more times (greedy)\n"
  "  *?         Match zero or more times (non-greedy)\n"
  "  ?          Match zero or once (greedy)\n"
  "  ??         Match zero or once (non-greedy)\n"
  "  x|y        Match x or y (alternation operator)\n"
  "  \\meta      Match one of the meta character: ^$().[]{}*+?|\\\n"
  "  \\x00       Match hex character code (exactly 2 digits)\n"
  "  \\u0000     Match hex character code (exactly 4 digits)\n"
  "  \\U00000000 Match hex character code (exactly 8 digits)\n"
  "  \\<, \\>     Match start-of-word and end-of-word\n"
  "  \\B         Matches a nonword boundary\n"
  "  [...]      Match any character from set. Ranges like [a-z] are supported\n"
  "  [^...]     Match any character but ones from set\n"
  "  {n}        Matches exactly n times\n"
  "  {n,}       Matches the preceding character at least n times (greedy)\n"
  "  {n,m}      Matches the preceding character at least n and at most m times (greedy)\n"
  "  {n,}?      Matches the preceding character at least n times (non-greedy)\n"
  "  {n,m}?     Matches the preceding character at least n and at most m times (non-greedy)\n\n"
  "Flags:\n"
  "  re.I, re.IGNORECASE    Perform case-insensitive matching\n"
  "  re.G, re.GLOBAL        Perform global matching\n"
  "  re.U, re.UTF8          Perform utf8 matching"
  ) {

  int argc = pkGetArgc(vm);
  if (!pkCheckArgcRange(vm, argc, 2, 3)) return;

  const char *input; uint32_t len; int global;
  RE* re = _re_init(vm, &input, &len, 3, &global);
  if (!re) return;

  _re_match(vm, re, input, len, global, false, true);
  re_free(re);
}

DEF(_reRange,
  "re.range(pattern:String, input:String[, flag: Number]) -> List",
  "Perform a regular expression match and return a list of range object.\n"
  "Run help(re.match) to show supported regex patterns."
  ) {

  int argc = pkGetArgc(vm);
  if (!pkCheckArgcRange(vm, argc, 2, 3)) return;

  const char *input; uint32_t len; int global;
  RE* re = _re_init(vm, &input, &len, 3, &global);
  if (!re) return;

  _re_match(vm, re, input, len, global, true, true);
  re_free(re);
}

DEF(_reTest,
  "re.test(pattern:String, input:String[, flag: Number]) -> Bool",
  "Perform a regular expression match and return true or false.\n"
  "Run help(re.match) to show supported regex patterns."
  ) {

  int argc = pkGetArgc(vm);
  if (!pkCheckArgcRange(vm, argc, 2, 3)) return;

  const char *input; uint32_t len;
  RE* re = _re_init(vm, &input, &len, 3, NULL);
  if (!re) return;

  _re_match(vm, re, input, len, false, true, false);
  pkSetSlotBool(vm, 0, pkListLength(vm, 0) != 0);
  re_free(re);
}

DEF(_reReplace,
  "re.replace(pattern:String, input:String, [by:String|Closure, flag:Number, limit:Number]) -> String",
  "Replaces [pattern] in [input] by the string [by] or the result of the [by()].\n"
  "Run help(re.match) to show supported regex patterns."
  ) {

  int argc = pkGetArgc(vm);
  if (!pkCheckArgcRange(vm, argc, 2, 5)) return;

  int callback = 0; const char *by = NULL; uint32_t by_len = 0;
  if (argc >= 3) {
    PkVarType type = pkGetSlotType(vm, 3);
    if (type == PK_CLOSURE) {
      callback = 3;

    } else if (type == PK_STRING) {
      by = pkGetSlotString(vm, 3, &by_len);

    } else {
      pkSetRuntimeError(vm, "Expected a 'String' or a 'Closure' at slot 3.");
      return;
    }
  }

  int32_t limit = -1;
  if (argc >= 5) {
    if (!pkValidateSlotInteger(vm, 5, &limit)) return;
  }

  const char *input; uint32_t len;
  RE* re = _re_init(vm, &input, &len, 4, NULL);
  if (!re) return;

  int groups = re_max_matches(re) / 2;
  pkReserveSlots(vm, groups + argc + 2);

  pkByteBuffer buff;
  pkByteBufferInit(&buff);

  uint32_t len0 = len;
  const char *ptr = input;
  while (ptr < input + len0 && limit != 0) {
    const char** matches = re_match(re, ptr, len);
    if (!matches || !matches[0] || !matches[1] || matches[0] == matches[1]) break;

    if (matches[0] - ptr != 0) {
      pkByteBufferAddString(&buff, vm, ptr, matches[0] - ptr);
    }
    if (callback) {
      for (int i = 0; i < re_max_matches(re); i += 2) {
        if (matches[i] && matches[i + 1]) {
          pkSetSlotStringLength(vm, argc + (i / 2) + 1,
            matches[i], matches[i + 1] - matches[i]);
        }
      }
      pkCallFunction(vm, callback, groups, argc + 1, 0);
      if (pkGetSlotType(vm, 0) == PK_STRING) {
        by = pkGetSlotString(vm, 0, &by_len);
        pkByteBufferAddString(&buff, vm, by, by_len);
      }
    } else if (by) {
      pkByteBufferAddString(&buff, vm, by, by_len);
    }

    len -= matches[1] - ptr;
    ptr = matches[1]; // point to last matched char
    if (limit > 0) limit--;
  }
  if (ptr < input + len0) {
    pkByteBufferAddString(&buff, vm, ptr, input + len0 - ptr);
  }

  String* str = newStringLength(vm, (const char*)buff.data, buff.count);
  pkByteBufferClear(&buff, vm);
  vm->fiber->ret[0] = VAR_OBJ(str);

  re_free(re);
}

DEF(_reSplit,
  "re.split(pattern:String, input:String[, flag:Number, limit:Number]) -> List",
  "Split string by a regular expression.\n"
  "Run help(re.match) to show supported regex patterns."
  ) {

  int argc = pkGetArgc(vm);
  if (!pkCheckArgcRange(vm, argc, 2, 4)) return;

  int32_t limit = -1;
  if (argc >= 4) {
    if (!pkValidateSlotInteger(vm, 4, &limit)) return;
  }

  const char *input; uint32_t len;
  RE* re = _re_init(vm, &input, &len, 3, NULL);
  if (!re) return;

  pkNewList(vm, 0);

  int splitCharMode = false;
  uint32_t len0 = len;
  const char *ptr = input;
  while (ptr < input + len0 && limit != 0) {
    const char** matches = re_match(re, ptr, len);
    if (!matches) break;

    if ((splitCharMode == false) &&
        (!matches[0] || !matches[1] || matches[0] == matches[1])) {
      // split into chars
      int insensitive, utf8;
      re_flags(re, &insensitive, &utf8);
      re_free(re);

      re = re_compile(".", insensitive, utf8);
      splitCharMode = true;
      continue;
    }

    if (!splitCharMode) {
      pkSetSlotStringLength(vm, 1, ptr, matches[0] - ptr);
    } else {
      pkSetSlotStringLength(vm, 1, matches[0], matches[1] - matches[0]);
    }
    pkListInsert(vm, 0, -1, 1);

    len -= matches[1] - ptr;
    ptr = matches[1]; // point to last matched char
    if (limit > 0) limit--;
  }
  if (!splitCharMode || ptr < input + len0) {
    pkSetSlotStringLength(vm, 1, ptr, input + len0 - ptr);
    pkListInsert(vm, 0, -1, 1);
  }
  re_free(re);
}

/*****************************************************************************/
/* MODULE REGISTER                                                           */
/*****************************************************************************/

void registerModuleRe(PKVM* vm) {
  PkHandle* re = pkNewModule(vm, "re");

  pkReserveSlots(vm, 2);
  pkSetSlotHandle(vm, 0, re);
  pkSetSlotNumber(vm, 1, RE_IGNORECASE);
  pkSetAttribute(vm, 0, "I", 1);
  pkSetAttribute(vm, 0, "IGNORECASE", 1);
  pkSetSlotNumber(vm, 1, RE_GLOBAL);
  pkSetAttribute(vm, 0, "G", 1);
  pkSetAttribute(vm, 0, "GLOBAL", 1);
  pkSetSlotNumber(vm, 1, RE_UTF8);
  pkSetAttribute(vm, 0, "U", 1);
  pkSetAttribute(vm, 0, "UTF8", 1);

  REGISTER_FN(re, "match", _reMatch, -1);
  REGISTER_FN(re, "range", _reRange, -1);
  REGISTER_FN(re, "test", _reTest, -1);
  REGISTER_FN(re, "replace", _reReplace, -1);
  REGISTER_FN(re, "split", _reSplit, -1);

  pkRegisterModule(vm, re);
  pkReleaseHandle(vm, re);
}
