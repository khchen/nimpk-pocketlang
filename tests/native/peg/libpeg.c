
#include <pocketlang.h>
#include "peppa.c"

typedef struct {
  void* ref;
} Ref;

void* _newGrammar(PKVM* vm) {
  Ref* r = pkRealloc(vm, NULL, sizeof(Ref));
  assert(r != NULL, "pkRealloc failed.");
  r->ref = NULL;
  return r;
}

void _deleteGrammar(PKVM* vm, void* ptr) {
  if (ptr != NULL && ((Ref*)ptr)->ref != NULL) {
    P4_DeleteGrammar((P4_Grammar*) ((Ref*)ptr)->ref);
  }
  pkRealloc(vm, ptr, 0);
}

void* _newSource(PKVM* vm) {
  Ref* r = pkRealloc(vm, NULL, sizeof(Ref));
  assert(r != NULL, "pkRealloc failed.");
  r->ref = NULL;
  return r;
}

void _deleteSource(PKVM* vm, void* ptr) {
  if (ptr != NULL && ((Ref*)ptr)->ref != NULL) {
    P4_DeleteSource((P4_Source*) ((Ref*)ptr)->ref);
  }
  pkRealloc(vm, ptr, 0);
}


PK_EXPORT void _initGrammar(PKVM* vm) {
  const char* rules;
  uint32_t len;
  if (!pkValidateSlotString(vm, 1, &rules, &len)) return;

  Ref* self = (Ref*) pkGetSelf(vm);
  P4_Result result = {0};
  if (P4_Ok == P4_LoadGrammarResult((char*) rules, &result)) {
    self->ref = (void*) result.grammar;
  } 
  else {
    pkSetRuntimeError(vm, result.errmsg);
  }
}

PK_EXPORT void _parseGrammar(PKVM* vm) {
  const char *content, *entry;
  uint32_t content_len, entry_len;
  if (!pkValidateSlotString(vm, 1, &content, &content_len)) return;
  if (!pkValidateSlotString(vm, 2, &entry, &entry_len)) return;

  Ref* self = (Ref*) pkGetSelf(vm);
  assert(self->ref, "Uninitialized grammar.");

  P4_Grammar* grammar = (P4_Grammar*)self->ref;

  P4_Source* source = P4_CreateSource((char*) content, (char*) entry);
  P4_Error err = P4_Parse(grammar, source);
  assert(err == P4_Ok, "P4_Parse(grammar, source)");
// *      if (P4_Ok != P4_Parse(grammar, source)) {
//  *          printf("msg=%s\n", P4_GetErrorMessage(source));
//  *      }
   
  P4_DeleteSource(source);
}


PK_EXPORT void _initSource(PKVM* vm) {
  const char *content, *entry;
  uint32_t content_len, entry_len;
  if (!pkValidateSlotString(vm, 1, &content, &content_len)) return;
  if (!pkValidateSlotString(vm, 2, &entry, &entry_len)) return;

  Ref* self = (Ref*) pkGetSelf(vm);
  self->ref = (void*) P4_CreateSource((char*) content, (char*) entry);
}


PK_EXPORT void hello(PKVM* vm) {

  P4_Grammar* grammar = P4_LoadGrammar("entry = i\"hello\\nworld\";");
  if (grammar == NULL) {
      printf("Error: CreateGrammar: Error.\n");
      return;
  }

  P4_Source* source = P4_CreateSource("Hello\nWORLD", "entry");
  P4_Parse(grammar, source);
  P4_Node* root = P4_GetSourceAst(source);
  char* text = P4_CopyNodeString(root);

  printf("root span: [%lu %lu]\n", root->slice.start.pos, root->slice.stop.pos);
  printf("root start: line=%lu offset=%lu\n", root->slice.start.lineno, root->slice.start.offset);
  printf("root stop: line=%lu offset=%lu\n", root->slice.stop.lineno, root->slice.stop.offset);
  printf("root next: %p\n", (void *)root->next);
  printf("root head: %p\n", (void *)root->head);
  printf("root tail: %p\n", (void *)root->tail);
  printf("root text: %s\n", text);

  free(text);

  P4_JsonifySourceAst(stdout, root, NULL);

  P4_DeleteSource(source);
  P4_DeleteGrammar(grammar);
}

PK_EXPORT PkHandle* pkExportModule(PKVM* vm) {
  PkHandle* peg = pkNewModule(vm, "peg");
  
  pkModuleAddFunction(vm, peg, "hello", hello, 0, NULL);

  PkHandle* clsGrammar = pkNewClass(vm, "Grammar", NULL, peg,
    _newGrammar, _deleteGrammar, NULL);

  pkClassAddMethod(vm, clsGrammar, "_init", _initGrammar, 1, NULL);
  pkClassAddMethod(vm, clsGrammar, "parse", _parseGrammar, 2, NULL);

  PkHandle* clsSource = pkNewClass(vm, "Source", NULL, peg,
    _newSource, _deleteSource, NULL);

  pkClassAddMethod(vm, clsSource, "_init", _initSource, 2, NULL);

  pkReleaseHandle(vm, clsGrammar);
  pkReleaseHandle(vm, clsSource);

  return peg;
}
