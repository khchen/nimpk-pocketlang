type
  PkVarType* = enum
    PK_OBJECT = 0
    PK_NULL
    PK_BOOL
    PK_NUMBER
    PK_STRING
    PK_LIST
    PK_MAP
    PK_RANGE
    PK_MODULE
    PK_CLOSURE
    PK_METHOD_BIND
    PK_FIBER
    PK_CLASS
    PK_INSTANCE
  PkResult* = enum
    PK_RESULT_SUCCESS = 0
    PK_RESULT_UNEXPECTED_EOF
    PK_RESULT_COMPILE_ERROR
    PK_RESULT_RUNTIME_ERROR
  PKVM* {.bycopy.} = object
  PkHandle* {.bycopy.} = object
  PkConfiguration* {.bycopy.} = object
    realloc_fn*: pkReallocFn
    stderr_write*: pkWriteFn
    stdout_write*: pkWriteFn
    stdin_read*: pkReadFn
    resolve_path_fn*: pkResolvePathFn
    load_script_fn*: pkLoadScriptFn
    load_dl_fn*: pkLoadDL
    import_dl_fn*: pkImportDL
    unload_dl_fn*: pkUnloadDL
    use_ansi_escape*: bool
    user_data*: pointer
  pkNativeFn* = proc (vm: ptr PKVM) {.cdecl.}
  pkReallocFn* = proc (memory: pointer, new_size: csize_t, user_data: pointer): pointer {.cdecl.}
  pkWriteFn* = proc (vm: ptr PKVM, text: cstring) {.cdecl.}
  pkReadFn* = proc (vm: ptr PKVM): cstring {.cdecl.}
  pkSignalFn* = proc (a1: pointer) {.cdecl.}
  pkLoadScriptFn* = proc (vm: ptr PKVM, path: cstring): cstring {.cdecl.}
  pkLoadDL* = proc (vm: ptr PKVM, path: cstring): pointer {.cdecl.}
  pkImportDL* = proc (vm: ptr PKVM, handle: pointer): ptr PkHandle {.cdecl.}
  pkUnloadDL* = proc (vm: ptr PKVM, handle: pointer) {.cdecl.}
  pkResolvePathFn* = proc (vm: ptr PKVM, `from`: cstring, path: cstring): cstring {.cdecl.}
  pkNewInstanceFn* = proc (vm: ptr PKVM): pointer {.cdecl.}
  pkDeleteInstanceFn* = proc (vm: ptr PKVM, a1: pointer) {.cdecl.}
when appType == "lib":
  type
    PkNativeApi* {.bycopy.} = object
      pkNewConfiguration*: proc (): PkConfiguration {.cdecl.}
      pkNewVM*: proc (config: ptr PkConfiguration): ptr PKVM {.cdecl.}
      pkFreeVM*: proc (vm: ptr PKVM) {.cdecl.}
      pkSetUserData*: proc (vm: ptr PKVM, user_data: pointer) {.cdecl.}
      pkGetUserData*: proc (vm: ptr PKVM): pointer {.cdecl.}
      pkRegisterBuiltinFn*: proc (vm: ptr PKVM, name: cstring, fn: pkNativeFn, arity: cint, docstring: cstring) {.cdecl.}
      pkAddSearchPath*: proc (vm: ptr PKVM, path: cstring) {.cdecl.}
      pkRealloc*: proc (vm: ptr PKVM, `ptr`: pointer, size: csize_t): pointer {.cdecl.}
      pkReleaseHandle*: proc (vm: ptr PKVM, handle: ptr PkHandle) {.cdecl.}
      pkNewModule*: proc (vm: ptr PKVM, name: cstring): ptr PkHandle {.cdecl.}
      pkRegisterModule*: proc (vm: ptr PKVM, module: ptr PkHandle) {.cdecl.}
      pkModuleAddFunction*: proc (vm: ptr PKVM, module: ptr PkHandle, name: cstring, fptr: pkNativeFn, arity: cint, docstring: cstring) {.cdecl.}
      pkNewClass*: proc (vm: ptr PKVM, name: cstring, base_class: ptr PkHandle, module: ptr PkHandle, new_fn: pkNewInstanceFn, delete_fn: pkDeleteInstanceFn, docstring: cstring): ptr PkHandle {.cdecl.}
      pkClassAddMethod*: proc (vm: ptr PKVM, cls: ptr PkHandle, name: cstring, fptr: pkNativeFn, arity: cint, docstring: cstring) {.cdecl.}
      pkModuleAddSource*: proc (vm: ptr PKVM, module: ptr PkHandle, source: cstring) {.cdecl.}
      pkRunString*: proc (vm: ptr PKVM, source: cstring): PkResult {.cdecl.}
      pkRunFile*: proc (vm: ptr PKVM, path: cstring): PkResult {.cdecl.}
      pkRunREPL*: proc (vm: ptr PKVM): PkResult {.cdecl.}
      pkSetRuntimeError*: proc (vm: ptr PKVM, message: cstring) {.cdecl.}
      pkGetSelf*: proc (vm: ptr PKVM): pointer {.cdecl.}
      pkGetArgc*: proc (vm: ptr PKVM): cint {.cdecl.}
      pkCheckArgcRange*: proc (vm: ptr PKVM, argc: cint, min: cint, max: cint): bool {.cdecl.}
      pkValidateSlotBool*: proc (vm: ptr PKVM, slot: cint, value: ptr bool): bool {.cdecl.}
      pkValidateSlotNumber*: proc (vm: ptr PKVM, slot: cint, value: ptr cdouble): bool {.cdecl.}
      pkValidateSlotInteger*: proc (vm: ptr PKVM, slot: cint, value: ptr int32): bool {.cdecl.}
      pkValidateSlotString*: proc (vm: ptr PKVM, slot: cint, value: ptr cstring, length: ptr uint32): bool {.cdecl.}
      pkValidateSlotType*: proc (vm: ptr PKVM, slot: cint, `type`: PkVarType): bool {.cdecl.}
      pkValidateSlotInstanceOf*: proc (vm: ptr PKVM, slot: cint, cls: cint): bool {.cdecl.}
      pkIsSlotInstanceOf*: proc (vm: ptr PKVM, inst: cint, cls: cint, val: ptr bool): bool {.cdecl.}
      pkReserveSlots*: proc (vm: ptr PKVM, count: cint) {.cdecl.}
      pkGetSlotsCount*: proc (vm: ptr PKVM): cint {.cdecl.}
      pkGetSlotType*: proc (vm: ptr PKVM, index: cint): PkVarType {.cdecl.}
      pkGetSlotBool*: proc (vm: ptr PKVM, index: cint): bool {.cdecl.}
      pkGetSlotNumber*: proc (vm: ptr PKVM, index: cint): cdouble {.cdecl.}
      pkGetSlotString*: proc (vm: ptr PKVM, index: cint, length: ptr uint32): cstring {.cdecl.}
      pkGetSlotHandle*: proc (vm: ptr PKVM, index: cint): ptr PkHandle {.cdecl.}
      pkGetSlotNativeInstance*: proc (vm: ptr PKVM, index: cint): pointer {.cdecl.}
      pkSetSlotNull*: proc (vm: ptr PKVM, index: cint) {.cdecl.}
      pkSetSlotBool*: proc (vm: ptr PKVM, index: cint, value: bool) {.cdecl.}
      pkSetSlotNumber*: proc (vm: ptr PKVM, index: cint, value: cdouble) {.cdecl.}
      pkSetSlotString*: proc (vm: ptr PKVM, index: cint, value: cstring) {.cdecl.}
      pkSetSlotStringLength*: proc (vm: ptr PKVM, index: cint, value: cstring, length: uint32) {.cdecl.}
      pkSetSlotHandle*: proc (vm: ptr PKVM, index: cint, handle: ptr PkHandle) {.cdecl.}
      pkGetSlotHash*: proc (vm: ptr PKVM, index: cint): uint32 {.cdecl.}
      pkPlaceSelf*: proc (vm: ptr PKVM, index: cint) {.cdecl.}
      pkGetClass*: proc (vm: ptr PKVM, instance: cint, index: cint) {.cdecl.}
      pkNewInstance*: proc (vm: ptr PKVM, cls: cint, index: cint, argc: cint, argv: cint): bool {.cdecl.}
      pkNewRange*: proc (vm: ptr PKVM, index: cint, first: cdouble, last: cdouble) {.cdecl.}
      pkNewList*: proc (vm: ptr PKVM, index: cint) {.cdecl.}
      pkNewMap*: proc (vm: ptr PKVM, index: cint) {.cdecl.}
      pkListInsert*: proc (vm: ptr PKVM, list: cint, index: int32, value: cint): bool {.cdecl.}
      pkListPop*: proc (vm: ptr PKVM, list: cint, index: int32, popped: cint): bool {.cdecl.}
      pkListLength*: proc (vm: ptr PKVM, list: cint): uint32 {.cdecl.}
      pkCallFunction*: proc (vm: ptr PKVM, fn: cint, argc: cint, argv: cint, ret: cint): bool {.cdecl.}
      pkCallMethod*: proc (vm: ptr PKVM, instance: cint, `method`: cstring, argc: cint, argv: cint, ret: cint): bool {.cdecl.}
      pkGetAttribute*: proc (vm: ptr PKVM, instance: cint, name: cstring, index: cint): bool {.cdecl.}
      pkSetAttribute*: proc (vm: ptr PKVM, instance: cint, name: cstring, value: cint): bool {.cdecl.}
      pkImportModule*: proc (vm: ptr PKVM, path: cstring, index: cint): bool {.cdecl.}
  var pk_api*: PkNativeApi
  proc pkInitApi(api: ptr PkNativeApi) {.cdecl, exportc, dynlib.} = pk_api = api[]
  proc pkNewConfiguration*(): PkConfiguration = pk_api.pkNewConfiguration()
  proc pkNewVM*(config: ptr PkConfiguration): ptr PKVM = pk_api.pkNewVM(config)
  proc pkFreeVM*(vm: ptr PKVM) = pk_api.pkFreeVM(vm)
  proc pkSetUserData*(vm: ptr PKVM, user_data: pointer) = pk_api.pkSetUserData(vm, user_data)
  proc pkGetUserData*(vm: ptr PKVM): pointer = pk_api.pkGetUserData(vm)
  proc pkRegisterBuiltinFn*(vm: ptr PKVM, name: cstring, fn: pkNativeFn, arity: cint, docstring: cstring) = pk_api.pkRegisterBuiltinFn(vm, name, fn, arity, docstring)
  proc pkAddSearchPath*(vm: ptr PKVM, path: cstring) = pk_api.pkAddSearchPath(vm, path)
  proc pkRealloc*(vm: ptr PKVM, `ptr`: pointer, size: csize_t): pointer = pk_api.pkRealloc(vm, `ptr`, size)
  proc pkReleaseHandle*(vm: ptr PKVM, handle: ptr PkHandle) = pk_api.pkReleaseHandle(vm, handle)
  proc pkNewModule*(vm: ptr PKVM, name: cstring): ptr PkHandle = pk_api.pkNewModule(vm, name)
  proc pkRegisterModule*(vm: ptr PKVM, module: ptr PkHandle) = pk_api.pkRegisterModule(vm, module)
  proc pkModuleAddFunction*(vm: ptr PKVM, module: ptr PkHandle, name: cstring, fptr: pkNativeFn, arity: cint, docstring: cstring) = pk_api.pkModuleAddFunction(vm, module, name, fptr, arity, docstring)
  proc pkNewClass*(vm: ptr PKVM, name: cstring, base_class: ptr PkHandle, module: ptr PkHandle, new_fn: pkNewInstanceFn, delete_fn: pkDeleteInstanceFn, docstring: cstring): ptr PkHandle = pk_api.pkNewClass(vm, name, base_class, module, new_fn, delete_fn, docstring)
  proc pkClassAddMethod*(vm: ptr PKVM, cls: ptr PkHandle, name: cstring, fptr: pkNativeFn, arity: cint, docstring: cstring) = pk_api.pkClassAddMethod(vm, cls, name, fptr, arity, docstring)
  proc pkModuleAddSource*(vm: ptr PKVM, module: ptr PkHandle, source: cstring) = pk_api.pkModuleAddSource(vm, module, source)
  proc pkRunString*(vm: ptr PKVM, source: cstring): PkResult = pk_api.pkRunString(vm, source)
  proc pkRunFile*(vm: ptr PKVM, path: cstring): PkResult = pk_api.pkRunFile(vm, path)
  proc pkRunREPL*(vm: ptr PKVM): PkResult = pk_api.pkRunREPL(vm)
  proc pkSetRuntimeError*(vm: ptr PKVM, message: cstring) = pk_api.pkSetRuntimeError(vm, message)
  proc pkGetSelf*(vm: ptr PKVM): pointer = pk_api.pkGetSelf(vm)
  proc pkGetArgc*(vm: ptr PKVM): cint = pk_api.pkGetArgc(vm)
  proc pkCheckArgcRange*(vm: ptr PKVM, argc: cint, min: cint, max: cint): bool = pk_api.pkCheckArgcRange(vm, argc, min, max)
  proc pkValidateSlotBool*(vm: ptr PKVM, slot: cint, value: ptr bool): bool = pk_api.pkValidateSlotBool(vm, slot, value)
  proc pkValidateSlotNumber*(vm: ptr PKVM, slot: cint, value: ptr cdouble): bool = pk_api.pkValidateSlotNumber(vm, slot, value)
  proc pkValidateSlotInteger*(vm: ptr PKVM, slot: cint, value: ptr int32): bool = pk_api.pkValidateSlotInteger(vm, slot, value)
  proc pkValidateSlotString*(vm: ptr PKVM, slot: cint, value: ptr cstring, length: ptr uint32): bool = pk_api.pkValidateSlotString(vm, slot, value, length)
  proc pkValidateSlotType*(vm: ptr PKVM, slot: cint, `type`: PkVarType): bool = pk_api.pkValidateSlotType(vm, slot, `type`)
  proc pkValidateSlotInstanceOf*(vm: ptr PKVM, slot: cint, cls: cint): bool = pk_api.pkValidateSlotInstanceOf(vm, slot, cls)
  proc pkIsSlotInstanceOf*(vm: ptr PKVM, inst: cint, cls: cint, val: ptr bool): bool = pk_api.pkIsSlotInstanceOf(vm, inst, cls, val)
  proc pkReserveSlots*(vm: ptr PKVM, count: cint) = pk_api.pkReserveSlots(vm, count)
  proc pkGetSlotsCount*(vm: ptr PKVM): cint = pk_api.pkGetSlotsCount(vm)
  proc pkGetSlotType*(vm: ptr PKVM, index: cint): PkVarType = pk_api.pkGetSlotType(vm, index)
  proc pkGetSlotBool*(vm: ptr PKVM, index: cint): bool = pk_api.pkGetSlotBool(vm, index)
  proc pkGetSlotNumber*(vm: ptr PKVM, index: cint): cdouble = pk_api.pkGetSlotNumber(vm, index)
  proc pkGetSlotString*(vm: ptr PKVM, index: cint, length: ptr uint32): cstring = pk_api.pkGetSlotString(vm, index, length)
  proc pkGetSlotHandle*(vm: ptr PKVM, index: cint): ptr PkHandle = pk_api.pkGetSlotHandle(vm, index)
  proc pkGetSlotNativeInstance*(vm: ptr PKVM, index: cint): pointer = pk_api.pkGetSlotNativeInstance(vm, index)
  proc pkSetSlotNull*(vm: ptr PKVM, index: cint) = pk_api.pkSetSlotNull(vm, index)
  proc pkSetSlotBool*(vm: ptr PKVM, index: cint, value: bool) = pk_api.pkSetSlotBool(vm, index, value)
  proc pkSetSlotNumber*(vm: ptr PKVM, index: cint, value: cdouble) = pk_api.pkSetSlotNumber(vm, index, value)
  proc pkSetSlotString*(vm: ptr PKVM, index: cint, value: cstring) = pk_api.pkSetSlotString(vm, index, value)
  proc pkSetSlotStringLength*(vm: ptr PKVM, index: cint, value: cstring, length: uint32) = pk_api.pkSetSlotStringLength(vm, index, value, length)
  proc pkSetSlotHandle*(vm: ptr PKVM, index: cint, handle: ptr PkHandle) = pk_api.pkSetSlotHandle(vm, index, handle)
  proc pkGetSlotHash*(vm: ptr PKVM, index: cint): uint32 = pk_api.pkGetSlotHash(vm, index)
  proc pkPlaceSelf*(vm: ptr PKVM, index: cint) = pk_api.pkPlaceSelf(vm, index)
  proc pkGetClass*(vm: ptr PKVM, instance: cint, index: cint) = pk_api.pkGetClass(vm, instance, index)
  proc pkNewInstance*(vm: ptr PKVM, cls: cint, index: cint, argc: cint, argv: cint): bool = pk_api.pkNewInstance(vm, cls, index, argc, argv)
  proc pkNewRange*(vm: ptr PKVM, index: cint, first: cdouble, last: cdouble) = pk_api.pkNewRange(vm, index, first, last)
  proc pkNewList*(vm: ptr PKVM, index: cint) = pk_api.pkNewList(vm, index)
  proc pkNewMap*(vm: ptr PKVM, index: cint) = pk_api.pkNewMap(vm, index)
  proc pkListInsert*(vm: ptr PKVM, list: cint, index: int32, value: cint): bool = pk_api.pkListInsert(vm, list, index, value)
  proc pkListPop*(vm: ptr PKVM, list: cint, index: int32, popped: cint): bool = pk_api.pkListPop(vm, list, index, popped)
  proc pkListLength*(vm: ptr PKVM, list: cint): uint32 = pk_api.pkListLength(vm, list)
  proc pkCallFunction*(vm: ptr PKVM, fn: cint, argc: cint, argv: cint, ret: cint): bool = pk_api.pkCallFunction(vm, fn, argc, argv, ret)
  proc pkCallMethod*(vm: ptr PKVM, instance: cint, `method`: cstring, argc: cint, argv: cint, ret: cint): bool = pk_api.pkCallMethod(vm, instance, `method`, argc, argv, ret)
  proc pkGetAttribute*(vm: ptr PKVM, instance: cint, name: cstring, index: cint): bool = pk_api.pkGetAttribute(vm, instance, name, index)
  proc pkSetAttribute*(vm: ptr PKVM, instance: cint, name: cstring, value: cint): bool = pk_api.pkSetAttribute(vm, instance, name, value)
  proc pkImportModule*(vm: ptr PKVM, path: cstring, index: cint): bool = pk_api.pkImportModule(vm, path, index)
  when defined(windows) and not defined(gcDestructors):
    import winim/lean
    proc NimMain() {.cdecl, importc.}
    proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID) : BOOL {.stdcall, exportc, dynlib.} =
      NimMain()
      return true
else:
  proc pkNewConfiguration*(): PkConfiguration {.importc, cdecl.}
  proc pkNewVM*(config: ptr PkConfiguration): ptr PKVM {.importc, cdecl.}
  proc pkFreeVM*(vm: ptr PKVM) {.importc, cdecl.}
  proc pkSetUserData*(vm: ptr PKVM, user_data: pointer) {.importc, cdecl.}
  proc pkGetUserData*(vm: ptr PKVM): pointer {.importc, cdecl.}
  proc pkRegisterBuiltinFn*(vm: ptr PKVM, name: cstring, fn: pkNativeFn, arity: cint, docstring: cstring) {.importc, cdecl.}
  proc pkAddSearchPath*(vm: ptr PKVM, path: cstring) {.importc, cdecl.}
  proc pkRealloc*(vm: ptr PKVM, `ptr`: pointer, size: csize_t): pointer {.importc, cdecl.}
  proc pkReleaseHandle*(vm: ptr PKVM, handle: ptr PkHandle) {.importc, cdecl.}
  proc pkNewModule*(vm: ptr PKVM, name: cstring): ptr PkHandle {.importc, cdecl.}
  proc pkRegisterModule*(vm: ptr PKVM, module: ptr PkHandle) {.importc, cdecl.}
  proc pkModuleAddFunction*(vm: ptr PKVM, module: ptr PkHandle, name: cstring, fptr: pkNativeFn, arity: cint, docstring: cstring) {.importc, cdecl.}
  proc pkNewClass*(vm: ptr PKVM, name: cstring, base_class: ptr PkHandle, module: ptr PkHandle, new_fn: pkNewInstanceFn, delete_fn: pkDeleteInstanceFn, docstring: cstring): ptr PkHandle {.importc, cdecl.}
  proc pkClassAddMethod*(vm: ptr PKVM, cls: ptr PkHandle, name: cstring, fptr: pkNativeFn, arity: cint, docstring: cstring) {.importc, cdecl.}
  proc pkModuleAddSource*(vm: ptr PKVM, module: ptr PkHandle, source: cstring) {.importc, cdecl.}
  proc pkRunString*(vm: ptr PKVM, source: cstring): PkResult {.importc, cdecl.}
  proc pkRunFile*(vm: ptr PKVM, path: cstring): PkResult {.importc, cdecl.}
  proc pkRunREPL*(vm: ptr PKVM): PkResult {.importc, cdecl.}
  proc pkSetRuntimeError*(vm: ptr PKVM, message: cstring) {.importc, cdecl.}
  proc pkSetRuntimeErrorFmt*(vm: ptr PKVM, fmt: cstring) {.importc, cdecl, varargs.}
  proc pkGetSelf*(vm: ptr PKVM): pointer {.importc, cdecl.}
  proc pkGetArgc*(vm: ptr PKVM): cint {.importc, cdecl.}
  proc pkCheckArgcRange*(vm: ptr PKVM, argc: cint, min: cint, max: cint): bool {.importc, cdecl.}
  proc pkValidateSlotBool*(vm: ptr PKVM, slot: cint, value: ptr bool): bool {.importc, cdecl.}
  proc pkValidateSlotNumber*(vm: ptr PKVM, slot: cint, value: ptr cdouble): bool {.importc, cdecl.}
  proc pkValidateSlotInteger*(vm: ptr PKVM, slot: cint, value: ptr int32): bool {.importc, cdecl.}
  proc pkValidateSlotString*(vm: ptr PKVM, slot: cint, value: ptr cstring, length: ptr uint32): bool {.importc, cdecl.}
  proc pkValidateSlotType*(vm: ptr PKVM, slot: cint, `type`: PkVarType): bool {.importc, cdecl.}
  proc pkValidateSlotInstanceOf*(vm: ptr PKVM, slot: cint, cls: cint): bool {.importc, cdecl.}
  proc pkIsSlotInstanceOf*(vm: ptr PKVM, inst: cint, cls: cint, val: ptr bool): bool {.importc, cdecl.}
  proc pkReserveSlots*(vm: ptr PKVM, count: cint) {.importc, cdecl.}
  proc pkGetSlotsCount*(vm: ptr PKVM): cint {.importc, cdecl.}
  proc pkGetSlotType*(vm: ptr PKVM, index: cint): PkVarType {.importc, cdecl.}
  proc pkGetSlotBool*(vm: ptr PKVM, index: cint): bool {.importc, cdecl.}
  proc pkGetSlotNumber*(vm: ptr PKVM, index: cint): cdouble {.importc, cdecl.}
  proc pkGetSlotString*(vm: ptr PKVM, index: cint, length: ptr uint32): cstring {.importc, cdecl.}
  proc pkGetSlotHandle*(vm: ptr PKVM, index: cint): ptr PkHandle {.importc, cdecl.}
  proc pkGetSlotNativeInstance*(vm: ptr PKVM, index: cint): pointer {.importc, cdecl.}
  proc pkSetSlotNull*(vm: ptr PKVM, index: cint) {.importc, cdecl.}
  proc pkSetSlotBool*(vm: ptr PKVM, index: cint, value: bool) {.importc, cdecl.}
  proc pkSetSlotNumber*(vm: ptr PKVM, index: cint, value: cdouble) {.importc, cdecl.}
  proc pkSetSlotString*(vm: ptr PKVM, index: cint, value: cstring) {.importc, cdecl.}
  proc pkSetSlotStringLength*(vm: ptr PKVM, index: cint, value: cstring, length: uint32) {.importc, cdecl.}
  proc pkSetSlotStringFmt*(vm: ptr PKVM, index: cint, fmt: cstring) {.importc, cdecl, varargs.}
  proc pkSetSlotHandle*(vm: ptr PKVM, index: cint, handle: ptr PkHandle) {.importc, cdecl.}
  proc pkGetSlotHash*(vm: ptr PKVM, index: cint): uint32 {.importc, cdecl.}
  proc pkPlaceSelf*(vm: ptr PKVM, index: cint) {.importc, cdecl.}
  proc pkGetClass*(vm: ptr PKVM, instance: cint, index: cint) {.importc, cdecl.}
  proc pkNewInstance*(vm: ptr PKVM, cls: cint, index: cint, argc: cint, argv: cint): bool {.importc, cdecl.}
  proc pkNewRange*(vm: ptr PKVM, index: cint, first: cdouble, last: cdouble) {.importc, cdecl.}
  proc pkNewList*(vm: ptr PKVM, index: cint) {.importc, cdecl.}
  proc pkNewMap*(vm: ptr PKVM, index: cint) {.importc, cdecl.}
  proc pkListInsert*(vm: ptr PKVM, list: cint, index: int32, value: cint): bool {.importc, cdecl.}
  proc pkListPop*(vm: ptr PKVM, list: cint, index: int32, popped: cint): bool {.importc, cdecl.}
  proc pkListLength*(vm: ptr PKVM, list: cint): uint32 {.importc, cdecl.}
  proc pkCallFunction*(vm: ptr PKVM, fn: cint, argc: cint, argv: cint, ret: cint): bool {.importc, cdecl.}
  proc pkCallMethod*(vm: ptr PKVM, instance: cint, `method`: cstring, argc: cint, argv: cint, ret: cint): bool {.importc, cdecl.}
  proc pkGetAttribute*(vm: ptr PKVM, instance: cint, name: cstring, index: cint): bool {.importc, cdecl.}
  proc pkSetAttribute*(vm: ptr PKVM, instance: cint, name: cstring, value: cint): bool {.importc, cdecl.}
  proc pkImportModule*(vm: ptr PKVM, path: cstring, index: cint): bool {.importc, cdecl.}
