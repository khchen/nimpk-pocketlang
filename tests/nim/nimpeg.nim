import pegs
import pknative

converter int2cint(x: int): cint = cint x
converter int2uint32(x: int): uint32 = uint32 x

var nodeClassHandle: ptr PkHandle

type
  Pref = ref object
    peg: Peg

  Grammar = object
    pref: Pref

  NodeRef = ref object
    name: string
    slice: Slice[int]
    head: NodeRef
    tail: NodeRef
    next: NodeRef

  Node = object
    nref: NodeRef
    hsrc: ptr PkHandle

proc toString(cstr: cstring, cstrlen: uint32): string =
  if cstr != nil and cstrlen != 0:
    result = newString(cstrlen)
    copyMem(addr result[0], cstr, cstrlen)

proc grammarNew(vm: ptr PkVM): pointer {.cdecl.} =
  var grammar = cast[ptr Grammar](vm.pkRealloc(nil, csize_t sizeof(Grammar)))
  defer: return grammar

  if grammar == nil: vm.pkSetRuntimeError("pkRealloc failed.")
  else: zeroMem(grammar, sizeof(Grammar))

proc grammarDel(vm: ptr PkVM, self: pointer) {.cdecl.} =
  var grammar = cast[ptr Grammar](self)
  # set all element to nil or "" to ensure --gc:orc release this
  grammar.pref = nil
  discard vm.pkRealloc(self, 0)

proc nodeNew(vm: ptr PkVM): pointer {.cdecl.} =
  var node = cast[ptr Node](vm.pkRealloc(nil, csize_t sizeof(Node)))
  defer: return node

  if node == nil: vm.pkSetRuntimeError("pkRealloc failed.")
  else: zeroMem(node, sizeof(Node))

proc nodeDel(vm: ptr PkVM, self: pointer) {.cdecl.} =
  var node = cast[ptr Node](self)
  if cast[int](node.nref) == 0xbabef00d and cast[int](node.hsrc) == 0xbabef00d:
    vm.pkReleaseHandle(nodeClassHandle)
    nodeClassHandle = nil
    cast[ptr int](addr node.nref)[] = 0 # avoid destructor
    node.hsrc = nil

  else:
    # set all element to nil or "" to ensure --gc:orc release this
    node.nref = nil

    if node.hsrc != nil:
      vm.pkReleaseHandle(node.hsrc)
      node.hsrc = nil

  discard vm.pkRealloc(self, 0)

proc grammarInit(vm: ptr PkVM) {.cdecl.} =
  var
    grammar = cast[ptr Grammar](vm.pkGetSelf())
    cstr: cstring
    cstrlen: uint32

  if not vm.pkValidateSlotString(1, addr cstr, addr cstrlen): return
  try:
    var peg = peg(toString(cstr, cstrlen))
    grammar.pref = Pref(peg: peg) # cannot combine above two line to avoid memory leak

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc pkNewNode(vm: ptr PkVM, nr: NodeRef, hsrc: ptr PkHandle) =
  try:
    if nr == nil or nodeClassHandle == nil: raise
    vm.pkSetSlotHandle(0, nodeClassHandle)
    if not vm.pkNewInstance(0, 0, 0, 0): raise

    var node = cast[ptr Node](vm.pkGetSlotNativeInstance(0))
    vm.pkReserveSlots(2)
    vm.pkSetSlotHandle(1, hsrc)
    node.hsrc = vm.pkGetSlotHandle(1)
    node.nref = nr

  except:
    vm.pkSetSlotNull(0)

proc nodeGetter(vm: ptr PkVM) {.cdecl.} =
  var 
    node = cast[ptr Node](vm.pkGetSelf())
    cstr: cstring
    cstrlen: uint32

  if node.nref == nil:
    vm.pkSetRuntimeError("Invalid 'Node' object")
    return
  
  if not vm.pkValidateSlotString(1, addr cstr, addr cstrlen): return

  var attr = toString(cstr, cstrlen)
  case attr
  of "src", "source":
    vm.pkSetSlotHandle(0, node.hsrc)

  of "name":
    vm.pkSetSlotStringLength(0, cstring node.nref.name, node.nref.name.len)

  of "head":
    vm.pkNewNode(node.nref.head, node.hsrc)

  of "tail":
    vm.pkNewNode(node.nref.tail, node.hsrc)

  of "next":
    vm.pkNewNode(node.nref.next, node.hsrc)

  of "range":
    vm.pkNewRange(0, cdouble node.nref.slice.a, cdouble node.nref.slice.b)

  of "text":
    vm.pkSetSlotHandle(0, node.hsrc)
    var arr = cast[ptr UncheckedArray[char]](vm.pkGetSlotString(0, nil))
    vm.pkSetSlotStringLength(0, addr arr[node.nref.slice.a], node.nref.slice.len)

  else:
    vm.pkSetRuntimeError(cstring "'Node' object has no attribute named '" & attr & "'");

proc grammarParse(vm: ptr PkVM) {.cdecl.} =
  var
    grammar = cast[ptr Grammar](vm.pkGetSelf())
    cstr: cstring
    cstrlen: uint32
    root = NodeRef(name: "@root")
    nodeStack: seq[NodeRef] = @[]

  if not vm.pkValidateSlotString(1, addr cstr, addr cstrlen): return
  var str = toString(cstr, cstrlen)

  let
    parseArithExpr = grammar.pref.peg.eventParser:
      pkNonTerminal:
        enter:
          nodeStack.add NodeRef(name: p.nt.name)

        leave:
          var node = nodeStack.pop()
          if length != -1:
            var parent: NodeRef
            if nodeStack.len != 0:
              parent = nodeStack[^1]
            else:
              parent = root

            node.slice = start..start+length-1
            if parent.tail == nil:
              parent.tail = node
              parent.head = node

            else:
              parent.tail.next = node
              parent.tail = node

  var n = parseArithExpr(str)
  if n > 0:
    root.slice = 0 ..< n
    var handle = vm.pkGetSlotHandle(1)
    vm.pkNewNode(root, handle)
    vm.pkReleaseHandle(handle)

proc fillList(vm: ptr PkVM, list: cint, captures: openarray[string], unused: cint) =
  vm.pkReserveSlots(unused + 1)

  var last = -1
  for i in countdown(captures.len - 1, 0):
    if captures[i] != "":
      last = i
      break

  # clear the old list, is there a better way?
  for i in 0..<vm.pkListLength(list):
    discard vm.pkListPop(list, -1, -1)

  for i in 0..last:
    vm.pkSetSlotStringLength(unused, cstring captures[i], captures[i].len)
    discard vm.pkListInsert(list, -1, unused)

proc prepareArg1_2(vm: ptr PkVM): tuple[
    grammar: ptr Grammar,
    start: int32,
    str: string
  ] =

  var
    grammar = cast[ptr Grammar](vm.pkGetSelf())
    argc = vm.pkGetArgc()
    start: int32 = 0
    cstr: cstring
    cstrlen: uint32

  if grammar.pref == nil:
    vm.pkSetRuntimeError("Invalid 'Grammar' object")
    return

  if not vm.pkCheckArgcRange(argc, 1, 2): return
  if not vm.pkValidateSlotString(1, addr cstr, addr cstrlen): return

  if argc == 2:
    if not vm.pkValidateSlotInteger(2, addr start): return

  result.grammar = grammar
  result.start = start
  result.str = toString(cstr, cstrlen)

proc prepareArg1_3(vm: ptr PkVM): tuple[
    grammar: ptr Grammar,
    start: int32,
    str: string,
    capturesSlot: int32
  ] =

  var
    grammar = cast[ptr Grammar](vm.pkGetSelf())
    argc = vm.pkGetArgc()
    start: int32 = 0
    cstr: cstring
    cstrlen: uint32
    capturesSlot = -1

  if grammar.pref == nil:
    vm.pkSetRuntimeError("Invalid 'Grammar' object")
    return

  if not vm.pkCheckArgcRange(argc, 1, 3): return
  if not vm.pkValidateSlotString(1, addr cstr, addr cstrlen): return

  case argc
  of 3: # (string, capture, start)
    if not vm.pkValidateSlotType(2, PK_LIST): return
    if not vm.pkValidateSlotInteger(3, addr start): return
    capturesSlot = 2

  of 2: # (string, start) or (string, capture)
    case vm.pkGetSlotType(2)
    of PK_NUMBER:
      if not vm.pkValidateSlotInteger(2, addr start): return

    of PK_LIST:
      capturesSlot = 2

    else:
      vm.pkSetRuntimeError("Expected a 'Number' or a 'List' at slot 2")
      return

  else:
    discard

  result.grammar = grammar
  result.start = start
  result.str = toString(cstr, cstrlen)
  result.capturesSlot = capturesSlot

proc grammarMatch(vm: ptr PkVM) {.cdecl.} =
  var (grammar, start, str, capturesSlot) = vm.prepareArg1_3()
  if grammar == nil: return # runtime error should be there already

  try:
    var result: bool
    defer:
      vm.pkSetSlotBool(0, result)

    if capturesSlot > 0:
      var captures: array[MaxSubpatterns, string]
      result = match(str, grammar.pref.peg, captures, start)
      vm.fillList(capturesSlot, captures, 4)
    else:
      result = match(str, grammar.pref.peg, start)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc grammarMatchLen(vm: ptr PkVM) {.cdecl.} =
  var (grammar, start, str, capturesSlot) = vm.prepareArg1_3()
  if grammar == nil: return # runtime error should be there already

  try:
    var result: int
    defer:
      vm.pkSetSlotNumber(0, cdouble result)

    if capturesSlot > 0:
      var captures: array[MaxSubpatterns, string]
      result = matchLen(str, grammar.pref.peg, captures, start)
      vm.fillList(capturesSlot, captures, 4)
    else:
      result = matchLen(str, grammar.pref.peg, start)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc grammarFind(vm: ptr PkVM) {.cdecl.} =
  var (grammar, start, str, capturesSlot) = vm.prepareArg1_3()
  if grammar == nil: return # runtime error should be there already

  try:
    var result: int
    defer:
      vm.pkSetSlotNumber(0, cdouble result)

    if capturesSlot > 0:
      var captures: array[MaxSubpatterns, string]
      result = find(str, grammar.pref.peg, captures, start)
      vm.fillList(capturesSlot, captures, 4)
    else:
      result = find(str, grammar.pref.peg, start)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc grammarContains(vm: ptr PkVM) {.cdecl.} =
  var (grammar, start, str, capturesSlot) = vm.prepareArg1_3()
  if grammar == nil: return # runtime error should be there already

  try:
    var result: bool
    defer:
      vm.pkSetSlotBool(0, result)

    if capturesSlot > 0:
      var captures: array[MaxSubpatterns, string]
      result = contains(str, grammar.pref.peg, captures, start)
      vm.fillList(capturesSlot, captures, 4)
    else:
      result = contains(str, grammar.pref.peg, start)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc grammarFindBuonds(vm: ptr PkVM) {.cdecl.} =
  var (grammar, start, str, capturesSlot) = vm.prepareArg1_3()
  if grammar == nil: return # runtime error should be there already

  try:
    var
      result: tuple[first, last: int]
      captures: array[MaxSubpatterns, string]

    defer:
      vm.pkNewRange(0, cdouble result.first, cdouble result.last)

    result = findBounds(str, grammar.pref.peg, captures, start)
    if capturesSlot > 0:
      vm.fillList(capturesSlot, captures, 4)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc findAllGrammar(vm: ptr PkVM) {.cdecl.} =
  var (grammar, start, str) = vm.prepareArg1_2()
  if grammar == nil: return # runtime error should be there already
  
  try:
    var result = findAll(str, grammar.pref.peg, start)
    vm.pkNewList(0)
    for s in result:
      vm.pkSetSlotStringLength(1, cstring s, s.len)
      discard vm.pkListInsert(0, -1, 1)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc grammarStartsWith(vm: ptr PkVM) {.cdecl.} =
  var (grammar, start, str) = vm.prepareArg1_2()
  if grammar == nil: return # runtime error should be there already

  try:
    var result = startsWith(str, grammar.pref.peg, start)
    vm.pkSetSlotBool(0, result)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc grammarEndsWith(vm: ptr PkVM) {.cdecl.} =
  var (grammar, start, str) = vm.prepareArg1_2()
  if grammar == nil: return # runtime error should be there already

  try:
    var result = endsWith(str, grammar.pref.peg, start)
    vm.pkSetSlotBool(0, result)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc grammarReplace(vm: ptr PkVM) {.cdecl.} =
  var
    grammar = cast[ptr Grammar](vm.pkGetSelf())
    argc = vm.pkGetArgc()
    cstr: cstring
    cstrlen: uint32

  if grammar.pref == nil:
    vm.pkSetRuntimeError("Invalid 'Grammar' object")
    return

  if not vm.pkCheckArgcRange(argc, 1, 2): return
  if not vm.pkValidateSlotString(1, addr cstr, addr cstrlen): return

  try:
    var str = toString(cstr, cstrlen)
    defer:
      vm.pkSetSlotStringLength(0, cstring str, str.len)

    if argc == 1:
      str = replace(str, grammar.pref.peg)

    elif vm.pkGetSlotType(2) == PK_STRING:
      var
        bylen: uint32
        by = toString(vm.pkGetSlotString(2, addr bylen), bylen)

      str = replace(str, grammar.pref.peg, by)

    elif vm.pkGetSlotType(2) == PK_CLOSURE:
      if not vm.pkGetAttribute(2, "arity", 0) or vm.pkGetSlotNumber(0).int != 2:
        raise newException(Exception, "Expected exactly 2 argument(s) for callback function.")

      vm.pkReserveSlots(5)

      proc callback(m: int, n: int, c: openArray[string]): string =
        vm.pkSetSlotNumber(3, cdouble m)
        vm.pkNewList(4)
        for i in 0..<n:
          vm.pkSetSlotStringLength(0, cstring c[i], c[i].len)
          discard vm.pkListInsert(4, -1, 0)

        if not vm.pkCallFunction(2, 2, 3, 0):
          raise newException(Exception, "pkCallFunction failed.")

        if vm.pkGetSlotType(0) != PK_STRING:
          raise newException(Exception, "Expected return 'String' from callback function.")

        var cstrlen: uint32
        return toString(vm.pkGetSlotString(0, addr cstrlen), cstrlen)

      str = replace(str, grammar.pref.peg, callback)

    else:
      raise newException(Exception, "Expected a 'String' or a 'Closure' at slot 2")

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc grammarReplacef(vm: ptr PkVM) {.cdecl.} =
  var
    grammar = cast[ptr Grammar](vm.pkGetSelf())
    cstr, cstr2: cstring
    cstrlen, cstrlen2: uint32

  if grammar.pref == nil:
    vm.pkSetRuntimeError("Invalid 'Grammar' object")
    return

  if not vm.pkValidateSlotString(1, addr cstr, addr cstrlen): return
  if not vm.pkValidateSlotString(2, addr cstr2, addr cstrlen2): return

  try:
    var 
      str = toString(cstr, cstrlen)
      by = toString(cstr2, cstrlen2)

    defer:
      vm.pkSetSlotStringLength(0, cstring str, str.len)

    str = replacef(str, grammar.pref.peg, by)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())


proc grammarSplit(vm: ptr PkVM) {.cdecl.} =
  var
    grammar = cast[ptr Grammar](vm.pkGetSelf())
    cstr: cstring
    cstrlen: uint32

  if grammar.pref == nil:
    vm.pkSetRuntimeError("Invalid 'Grammar' object")
    return

  if not vm.pkValidateSlotString(1, addr cstr, addr cstrlen): return

  try:
    var 
      str = toString(cstr, cstrlen)
      result = split(str, grammar.pref.peg)

    vm.pkNewList(0)
    for s in result:
      vm.pkSetSlotStringLength(1, cstring s, s.len)
      discard vm.pkListInsert(0, -1, 1)

  except:
    vm.pkSetRuntimeError(cstring getCurrentExceptionMsg())

proc pkExportModule(vm: ptr PkVM): ptr PkHandle {.cdecl, exportc, dynlib.} =
  var nimpeg = vm.pkNewModule("nimpeg")

  var nodeClass = vm.pkNewClass("Node", nil, nimpeg, nodeNew, nodeDel, nil)
  vm.pkClassAddMethod(nodeClass, "@getter", nodeGetter, 1, nil)

  var grammarClass = vm.pkNewClass("Grammar", nil, nimpeg, grammarNew, grammarDel, nil)
  vm.pkClassAddMethod(grammarClass, "_init", grammarInit, 1, nil)
  vm.pkClassAddMethod(grammarClass, "parse", grammarParse, 1, nil)
  vm.pkClassAddMethod(grammarClass, "match", grammarMatch, -1, nil)
  vm.pkClassAddMethod(grammarClass, "matchLen", grammarMatchLen, -1, nil)
  vm.pkClassAddMethod(grammarClass, "find", grammarFind, -1, nil)
  vm.pkClassAddMethod(grammarClass, "contains", grammarContains, -1, nil)
  vm.pkClassAddMethod(grammarClass, "findBounds", grammarFindBuonds, -1, nil)
  vm.pkClassAddMethod(grammarClass, "findAll", findAllGrammar, -1, nil)
  vm.pkClassAddMethod(grammarClass, "startsWith", grammarStartsWith, -1, nil)
  vm.pkClassAddMethod(grammarClass, "endsWith", grammarEndsWith, -1, nil)
  vm.pkClassAddMethod(grammarClass, "replace", grammarReplace, -1, nil)
  vm.pkClassAddMethod(grammarClass, "replacef", grammarReplacef, 2, nil)
  vm.pkClassAddMethod(grammarClass, "split", grammarSplit, 1, nil)

  vm.pkReserveSlots(2)
  vm.pkSetSlotHandle(1, nodeClass)
  nodeClassHandle = vm.pkGetSlotHandle(1)

  if vm.pkNewInstance(1, 0, 0, 0):
    # a magic node object stored as attribute of module to release global nodeClassHandle
    var node = cast[ptr Node](vm.pkGetSlotNativeInstance(0))
    node.nref = cast[NodeRef](0xbabef00d)
    node.hsrc = cast[ptr PkHandle](0xbabef00d)

    vm.pkSetSlotHandle(1, nimpeg)
    discard vm.pkSetAttribute(1, "@internal", 0)

  vm.pkReleaseHandle(nodeClass)
  vm.pkReleaseHandle(grammarClass)

  return nimpeg
