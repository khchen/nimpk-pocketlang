
#include <pocketlang.h>
#include "peppa.c"

typedef struct {
  P4_Grammar* p4grammar;
} Grammar;

typedef struct {
  P4_Source* p4source;
  PkHandle* src_handle;
} Source;

typedef struct {
  P4_Node* p4node;
  PkHandle* src_handle;
} Node;

void* _newGrammar(PKVM* vm) {
  Grammar* grammar = pkRealloc(vm, NULL, sizeof(Grammar));
  assert(grammar != NULL, "pkRealloc failed.");
  grammar->p4grammar = NULL;
  return grammar;
}

void _deleteGrammar(PKVM* vm, void* ptr) {
  Grammar* grammar = (Grammar*) ptr;
  if (grammar != NULL && grammar->p4grammar != NULL) {
    P4_DeleteGrammar(grammar->p4grammar);
    grammar->p4grammar = NULL;
  }
  pkRealloc(vm, ptr, 0);
}

void* _newSource(PKVM* vm) {
  Source* source = pkRealloc(vm, NULL, sizeof(Source));
  assert(source != NULL, "pkRealloc failed.");
  source->p4source = NULL;
  return source;
}

void _deleteSource(PKVM* vm, void* ptr) {
  Source* source = (Source*) ptr;
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
  }
  pkRealloc(vm, ptr, 0);
}

PK_EXPORT void _initGrammar(PKVM* vm) {
  const char* rules;
  uint32_t len;
  if (!pkValidateSlotString(vm, 1, &rules, &len)) return;

  Grammar* self = (Grammar*) pkGetSelf(vm);
  P4_Result result = {0};
  if (P4_Ok == P4_LoadGrammarResult((char*) rules, &result)) {
    self->p4grammar = (void*) result.grammar;
  } 
  else {
    pkSetRuntimeError(vm, result.errmsg);
  }
}

PK_EXPORT void _initSource(PKVM* vm) {
}

PK_EXPORT void _initNode(PKVM* vm) {
}

PK_EXPORT void _parseGrammar(PKVM* vm) {
  const char *content, *entry;
  if (!pkValidateSlotString(vm, 1, &content, NULL)) return;
  if (!pkValidateSlotString(vm, 2, &entry, NULL)) return;

  Grammar* self = (Grammar*) pkGetSelf(vm);
  if (!self->p4grammar) UNREACHABLE();

  // Create instance of Source class
  if (!pkImportModule(vm, "peg", 0)) return;
  if (!pkGetAttribute(vm, 0, "Source", 0)) return;
  if (!pkNewInstance(vm, 0, 0, 0, 0)) return;

  // slot[0] is instance of Source now.
  Source* source = pkGetSlotNativeInstance(vm, 0);
  if (!source) UNREACHABLE();

  source->p4source = P4_CreateSource((char*) content, (char*) entry);
  source->src_handle = pkGetSlotHandle(vm, 1);

  P4_Error err = P4_Parse(self->p4grammar, source->p4source);
  if (err != P4_Ok) {
    pkSetRuntimeError(vm, P4_GetErrorString(err));
    return;
  }

  // Create instance of Node class
  if (!pkImportModule(vm, "peg", 2)) return;
  if (!pkGetAttribute(vm, 2, "Node", 2)) return;
  if (!pkNewInstance(vm, 2, 2, 0, 0)) return;

  // slot[2] is instance of Node now.
  // if (!pkSetAttribute(vm, 0, "root", 2)) return; // source.root = node
  
  // Node* node = pkGetSlotNativeInstance(vm, 2);
  // if (!node) UNREACHABLE();

  // node->p4node = P4_GetSourceAst(source->p4source);
  // node->src_handle = pkGetSlotHandle(vm, 1);
}

PK_EXPORT void _sourceGetter(PKVM* vm) {
  Source* source = (Source*) pkGetSelf(vm);
  if (!source->p4source || !source->src_handle) {
    pkSetRuntimeError(vm, "invalid source object");
  }

  const char* attr = pkGetSlotString(vm, 1, NULL);
  if (strcmp("source", attr) == 0) {
    pkSetSlotHandle(vm, 0, source->src_handle);
  }
}

PK_EXPORT void _nodeGetter(PKVM* vm) {
  Node* node = (Node*) pkGetSelf(vm);
  if (!node->p4node) {
    pkSetRuntimeError(vm, "invalid node");
    return;
  }

  const char* attr = pkGetSlotString(vm, 1, NULL);
  if (strcmp("name", attr) == 0) {
    pkSetSlotString(vm, 0, node->p4node->rule_name);
    return;
  }
  else if (strcmp("text", attr) == 0) {
    pkSetSlotString(vm, 0, node->p4node->text);
  }
  else {
    pkSetRuntimeError(vm, "invalid node attribute");
  }
}

// typedef struct {
//   void* ref;
// } Ref;

// typedef struct {
//   P4_Node* node;
//   PkHandle* src_handle;
// } Node;

// void* _newNode(PKVM* vm) {
//   Node* n = pkRealloc(vm, NULL, sizeof(Node));
//   assert(n != NULL, "pkRealloc failed.");
//   n->node = NULL;
//   n->src_handle = NULL;
//   // return r;
// }

// void _deleteNode(PKVM* vm, void* ptr) {
//   Node* n = (Node*) ptr;
//   if (n->src_handle) {

//   }
//   // don't need to delete node because it will be delete by 
//   if (ptr != NULL && ((Ref*)ptr)->ref != NULL) {
//     P4_DeleteGrammar((P4_Grammar*) ((Ref*)ptr)->ref);
//   }
//   pkRealloc(vm, ptr, 0);
// }



// void* _newSource(PKVM* vm) {
//   Ref* r = pkRealloc(vm, NULL, sizeof(Ref));
//   assert(r != NULL, "pkRealloc failed.");
//   r->ref = NULL;
//   return r;
// }

// void _deleteSource(PKVM* vm, void* ptr) {
//   if (ptr != NULL && ((Ref*)ptr)->ref != NULL) {
//     P4_DeleteSource((P4_Source*) ((Ref*)ptr)->ref);
//   }
//   pkRealloc(vm, ptr, 0);
// }



// PK_EXPORT void _parseGrammar(PKVM* vm) {
//   const char *content, *entry;
//   uint32_t content_len, entry_len;
//   if (!pkValidateSlotString(vm, 1, &content, &content_len)) return;
//   if (!pkValidateSlotString(vm, 2, &entry, &entry_len)) return;

//   Ref* self = (Ref*) pkGetSelf(vm);
//   assert(self->ref, "Uninitialized grammar.");

//   P4_Grammar* grammar = (P4_Grammar*)self->ref;
//   P4_Source* source = P4_CreateSource((char*) content, (char*) entry);
//   ((char *)content)[0] = 'x';
  
//   P4_Error err = P4_Parse(grammar, source);
//   if (err != P4_Ok) {
//     pkSetRuntimeError(vm, P4_GetErrorString(err));
//   } else {
//     P4_Node* root = P4_GetSourceAst(source);
//     char* text = P4_CopyNodeString(root);

//     printf("root span: [%lu %lu]\n", root->slice.start.pos, root->slice.stop.pos);
//     printf("root start: line=%lu offset=%lu\n", root->slice.start.lineno, root->slice.start.offset);
//     printf("root stop: line=%lu offset=%lu\n", root->slice.stop.lineno, root->slice.stop.offset);
//     printf("root next: %p\n", (void *)root->next);
//     printf("root head: %p\n", (void *)root->head);
//     printf("root tail: %p\n", (void *)root->tail);
//     printf("root text: %s\n", text);
//     free(text);

//     P4_JsonifySourceAst(stdout, root, NULL);

//   }
//   P4_DeleteSource(source);
// }


// PK_EXPORT void _initSource(PKVM* vm) {
//   const char *content, *entry;
//   uint32_t content_len, entry_len;
//   if (!pkValidateSlotString(vm, 1, &content, &content_len)) return;
//   if (!pkValidateSlotString(vm, 2, &entry, &entry_len)) return;

//   Ref* self = (Ref*) pkGetSelf(vm);
//   self->ref = (void*) P4_CreateSource((char*) content, (char*) entry);
// }


// PK_EXPORT void hello(PKVM* vm) {

//   P4_Grammar* grammar = P4_LoadGrammar("entry = i\"hello\\nworld\";");
//   if (grammar == NULL) {
//       printf("Error: CreateGrammar: Error.\n");
//       return;
//   }

//   P4_Source* source = P4_CreateSource("Hello\nWORLD", "entry");
//   P4_Parse(grammar, source);
//   P4_Node* root = P4_GetSourceAst(source);
//   char* text = P4_CopyNodeString(root);

//   printf("root span: [%lu %lu]\n", root->slice.start.pos, root->slice.stop.pos);
//   printf("root start: line=%lu offset=%lu\n", root->slice.start.lineno, root->slice.start.offset);
//   printf("root stop: line=%lu offset=%lu\n", root->slice.stop.lineno, root->slice.stop.offset);
//   printf("root next: %p\n", (void *)root->next);
//   printf("root head: %p\n", (void *)root->head);
//   printf("root tail: %p\n", (void *)root->tail);
//   printf("root text: %s\n", text);

//   free(text);

//   P4_JsonifySourceAst(stdout, root, NULL);

//   P4_DeleteSource(source);
//   P4_DeleteGrammar(grammar);
// }

PK_EXPORT PkHandle* pkExportModule(PKVM* vm) {
  PkHandle* peg = pkNewModule(vm, "peg");

  PkHandle* clsGrammar = pkNewClass(vm, "Grammar", NULL, peg,
    _newGrammar, _deleteGrammar, NULL);

  PkHandle* clsSource = pkNewClass(vm, "Source", NULL, peg,
    _newSource, _deleteSource, NULL);

  PkHandle* clsNode = pkNewClass(vm, "Node", NULL, peg,
    _newNode, _deleteNode, NULL);

  pkClassAddMethod(vm, clsGrammar, "_init", _initGrammar, 1, NULL);
  pkClassAddMethod(vm, clsGrammar, "parse", _parseGrammar, 2, NULL);

  pkClassAddMethod(vm, clsSource, "@getter", _sourceGetter, 1, NULL);
  pkClassAddMethod(vm, clsNode, "@getter", _nodeGetter, 1, NULL);
  

  // pkClassAddMethod(vm, clsSource, "_init", _initSource, 0, NULL);
  // pkClassAddMethod(vm, clsNode, "_init", _initNode, 0, NULL);


  // pkModuleAddFunction(vm, peg, "hello", hello, 0, NULL);

  // PkHandle* clsGrammar = pkNewClass(vm, "Grammar", NULL, peg,
  //   _newGrammar, _deleteGrammar, NULL);

  

  // pkClassAddMethod(vm, clsSource, "_init", _initSource, 2, NULL);

  pkReleaseHandle(vm, clsGrammar);
  pkReleaseHandle(vm, clsSource);
  pkReleaseHandle(vm, clsNode);

  return peg;
}
