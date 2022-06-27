
#include <pocketlang.h>
#include "peppa.c"

typedef struct {
  P4_Grammar* p4grammar;
  PkHandle* errmsg_handle;
  P4_Error error_code;
} Grammar;

// PeppaPEG won't cache the source stirng, so we have to keep a handle of
// source string.
typedef struct {
  P4_Source* p4source;
  PkHandle* src_handle;
  P4_Error error_code;
} Result;

// P4_DeleteSource will let all P4_Node become unavailable.
// So we must ensure that Result instance won't be deleted before any related
// Node instance.
typedef struct {
  P4_Node* p4node;
  PkHandle* src_handle;
  PkHandle* ret_handle; // store a handle to source instance to avoid gc
} Node;

void* _newGrammar(PKVM* vm) {
  Grammar* grammar = pkRealloc(vm, NULL, sizeof(Grammar));
  assert(grammar != NULL, "pkRealloc failed.");
  grammar->p4grammar = NULL;
  grammar->errmsg_handle = NULL;
  grammar->error_code = P4_Ok;
  return grammar;
}

void _deleteGrammar(PKVM* vm, void* ptr) {
  Grammar* grammar = (Grammar*) ptr;
  if (grammar != NULL) {
    if (grammar->p4grammar != NULL) {
      P4_DeleteGrammar(grammar->p4grammar);
      grammar->p4grammar = NULL;
    }
    if (grammar->errmsg_handle) {
      pkReleaseHandle(vm, grammar->errmsg_handle);
      grammar->errmsg_handle = NULL;
    }
  }
  pkRealloc(vm, ptr, 0);
}

void* _newResult(PKVM* vm) {
  Result* result = pkRealloc(vm, NULL, sizeof(Result));
  assert(result != NULL, "pkRealloc failed.");
  result->p4source = NULL;
  result->src_handle = NULL;
  result->error_code = P4_Ok;
  return result;
}

void _deleteResult(PKVM* vm, void* ptr) {
  Result* source = (Result*) ptr;
  if (source != NULL) {
    if (source->p4source != NULL) {
      P4_DeleteSource(source->p4source);
      source->p4source = NULL;
    }
    if (source->src_handle != NULL) {
      pkReleaseHandle(vm, source->src_handle);
      source->src_handle = NULL;
    }
  }
  pkRealloc(vm, ptr, 0);
}

void* _newNode(PKVM* vm) {
  Node* node = pkRealloc(vm, NULL, sizeof(Node));
  assert(node != NULL, "pkRealloc failed.");
  node->p4node = NULL;
  node->src_handle = node->ret_handle = NULL;
  return node;
}

void _deleteNode(PKVM* vm, void* ptr) {
  Node* node = (Node*) ptr;
  if (node != NULL) {
    node->p4node = NULL;
    if (node->src_handle != NULL) {
      pkReleaseHandle(vm, node->src_handle);
      node->src_handle = NULL;
    }
    if (node->ret_handle != NULL) {
      pkReleaseHandle(vm, node->ret_handle);
      node->ret_handle = NULL;
    }
  }
  pkRealloc(vm, ptr, 0);
}

PK_EXPORT void _initGrammar(PKVM* vm) {
  const char* rules;
  uint32_t len;
  if (!pkValidateSlotString(vm, 1, &rules, &len)) return;

  Grammar* grammar = (Grammar*) pkGetSelf(vm);
  P4_Result result = {0};

  grammar->error_code = P4_LoadGrammarResult((char*) rules, &result);
  if (grammar->error_code == P4_Ok) {
    grammar->p4grammar = (void*) result.grammar;
  }
  else {
    pkSetSlotString(vm, 1, result.errmsg);
    grammar->errmsg_handle = pkGetSlotHandle(vm, 1);
  }
}

PK_EXPORT void _parseGrammar(PKVM* vm) {
  const char *content, *entry;
  if (!pkValidateSlotString(vm, 1, &content, NULL)) return;
  if (!pkValidateSlotString(vm, 2, &entry, NULL)) return;

  Grammar* grammar = (Grammar*) pkGetSelf(vm);
  if (!grammar->p4grammar || grammar->error_code != P4_Ok) {
    pkSetRuntimeError(vm, "invalid grammar object");
    return;
  }

  // Create instance of Result class at slot[0]
  if (!pkImportModule(vm, "peg", 0)) return;
  if (!pkGetAttribute(vm, 0, "Result", 0)) return;
  if (!pkNewInstance(vm, 0, 0, 0, 0)) return;

  Result* result = pkGetSlotNativeInstance(vm, 0);
  if (!result) UNREACHABLE();


  result->p4source = P4_CreateSource((char*) content, (char*) entry);
  result->src_handle = pkGetSlotHandle(vm, 1);
  printf("%d\n", grammar->p4grammar);
  printf("%d\n", result->p4source);

  result->error_code = P4_Parse(grammar->p4grammar, result->p4source);
  printf("result->error_code %d\n", result->error_code);

  // ast may be null if source is empty or any other case?
  if (result->error_code == P4_Ok && P4_GetSourceAst(result->p4source) == NULL) {
    result->error_code = P4_NullError;
  }
}

static void createNode(PKVM* vm, P4_Node* p4node,
    PkHandle* src_handle, PkHandle* ret_handle, int unused) {

  pkSetSlotNull(vm, 0);
  if (!p4node) return;

  // Create instance of Node
  // slot[unused] is Node class, slot[0] is Node instance.
  pkReserveSlots(vm, unused + 1);
  if (!pkImportModule(vm, "peg", unused)) return;
  if (!pkGetAttribute(vm, unused, "Node", unused)) return;
  if (!pkNewInstance(vm, unused, 0, 0, 0)) return;

  Node* node = pkGetSlotNativeInstance(vm, 0);
  if (!node) UNREACHABLE();

  // copy the src_handle and ret_handle
  pkSetSlotHandle(vm, unused, src_handle);
  node->src_handle = pkGetSlotHandle(vm, unused);
  pkSetSlotHandle(vm, unused, ret_handle);
  node->ret_handle = pkGetSlotHandle(vm, unused);

  node->p4node = p4node;
}

PK_EXPORT void _grammarGetter(PKVM* vm) {
  Grammar* grammar = (Grammar*) pkGetSelf(vm);

  const char* attr = pkGetSlotString(vm, 1, NULL);
  if (strcmp("error", attr) == 0) {
    if (grammar->errmsg_handle) {
      pkSetSlotHandle(vm, 0, grammar->errmsg_handle);
    }
  } else if (strcmp("error_code", attr) == 0) {
    pkSetSlotNumber(vm, 0, (double) grammar->error_code);

  } else {
    pkSetRuntimeError(vm, "invalid attribute");
  }
}

PK_EXPORT void _resultGetter(PKVM* vm) {
  Result* result = (Result*) pkGetSelf(vm);
  if (!result->p4source || !result->src_handle) {
    pkSetRuntimeError(vm, "invalid object");
    return;
  }

  const char* attr = pkGetSlotString(vm, 1, NULL);
  if (strcmp("source", attr) == 0) {
    pkSetSlotHandle(vm, 0, result->src_handle);

  } else if (strcmp("root", attr) == 0) {
    pkPlaceSelf(vm, 0);
    PkHandle* ret_handle = pkGetSlotHandle(vm, 0);
    P4_Node* node = P4_GetSourceAst(result->p4source);
    createNode(vm, node, result->src_handle, ret_handle, 2);
    pkReleaseHandle(vm, ret_handle);

  } else if (strcmp("error", attr) == 0) {
    if (result->error_code != P4_Ok) {
      pkSetSlotString(vm, 0, P4_GetErrorString(result->error_code));
    }

  } else if (strcmp("error_code", attr) == 0) {
    pkSetSlotNumber(vm, 0, (double) result->error_code);

  } else {
    pkSetRuntimeError(vm, "invalid attribute");
  }
}

PK_EXPORT void _nodeGetter(PKVM* vm) {
  Node* self = (Node*) pkGetSelf(vm);
  if (!self->p4node) {
    pkSetRuntimeError(vm, "invalid object");
    return;
  }

  const char* attr = pkGetSlotString(vm, 1, NULL);
  if (strcmp("source", attr) == 0) {
    pkSetSlotHandle(vm, 0, self->src_handle);

  } else if (strcmp("name", attr) == 0) {
    pkSetSlotString(vm, 0, self->p4node->rule_name);

  } else if (strcmp("text", attr) == 0) {
    pkSetSlotHandle(vm, 0, self->src_handle);
    const char* src = pkGetSlotString(vm, 0, NULL);
    uint32_t len = get_slice_size(&self->p4node->slice);
    pkSetSlotStringLength(vm, 0, src + self->p4node->slice.start.pos, len);

  } else if (strcmp("range", attr) == 0) {
    pkNewRange(vm, 0, self->p4node->slice.start.pos,
      self->p4node->slice.stop.pos - 1);

  } else if (strcmp("next", attr) == 0) {
    createNode(vm, self->p4node->next, self->src_handle, self->ret_handle, 2);

  } else if (strcmp("head", attr) == 0) {
    createNode(vm, self->p4node->head, self->src_handle, self->ret_handle, 2);

  } else if (strcmp("tail", attr) == 0) {
    createNode(vm, self->p4node->tail, self->src_handle, self->ret_handle, 2);

  } else {
    pkSetRuntimeError(vm, "invalid attribute");
  }
}

PK_EXPORT PkHandle* pkExportModule(PKVM* vm) {
  PkHandle* peg = pkNewModule(vm, "peg");

  PkHandle* clsGrammar = pkNewClass(vm, "Grammar", NULL, peg,
    _newGrammar, _deleteGrammar, NULL);

  PkHandle* clsResult = pkNewClass(vm, "Result", NULL, peg,
    _newResult, _deleteResult, NULL);

  PkHandle* clsNode = pkNewClass(vm, "Node", NULL, peg,
    _newNode, _deleteNode, NULL);

  pkClassAddMethod(vm, clsGrammar, "_init", _initGrammar, 1, NULL);
  pkClassAddMethod(vm, clsGrammar, "parse", _parseGrammar, 2, NULL);

  pkClassAddMethod(vm, clsGrammar, "@getter", _grammarGetter, 1, NULL);
  pkClassAddMethod(vm, clsResult, "@getter", _resultGetter, 1, NULL);
  pkClassAddMethod(vm, clsNode, "@getter", _nodeGetter, 1, NULL);

  pkReleaseHandle(vm, clsGrammar);
  pkReleaseHandle(vm, clsResult);
  pkReleaseHandle(vm, clsNode);

  return peg;
}
