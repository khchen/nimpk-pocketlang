##
##   Copyright (c) 2020-2022 Thakee Nathees
##   Copyright (c) 2021-2022 Pocketlang Contributors
##   Distributed Under The MIT License
##

##  !! THIS FILE IS GENERATED DO NOT EDIT !!

import pocketlang
export PkVM, PkHandle, pkNativeFn, pkReallocFn, pkWriteFn, pkReadFn, pkSignalFn, pkLoadScriptFn, pkLoadDL, pkImportDL, pkUnloadDL, pkResolvePathFn, pkNewInstanceFn, pkDeleteInstanceFn, PkVarType, PkResult, PkConfiguration

type
  PkNativeApi* {.bycopy.} = object
    pkNewConfiguration_ptr*: pkNewConfiguration.type
    pkNewVM_ptr*: pkNewVM.type
    pkFreeVM_ptr*: pkFreeVM.type
    pkSetUserData_ptr*: pkSetUserData.type
    pkGetUserData_ptr*: pkGetUserData.type
    pkRegisterBuiltinFn_ptr*: pkRegisterBuiltinFn.type
    pkAddSearchPath_ptr*: pkAddSearchPath.type
    pkRealloc_ptr*: pkRealloc.type
    pkReleaseHandle_ptr*: pkReleaseHandle.type
    pkNewModule_ptr*: pkNewModule.type
    pkRegisterModule_ptr*: pkRegisterModule.type
    pkModuleAddFunction_ptr*: pkModuleAddFunction.type
    pkNewClass_ptr*: pkNewClass.type
    pkClassAddMethod_ptr*: pkClassAddMethod.type
    pkModuleAddSource_ptr*: pkModuleAddSource.type
    pkRunString_ptr*: pkRunString.type
    pkRunFile_ptr*: pkRunFile.type
    pkRunREPL_ptr*: pkRunREPL.type
    pkSetRuntimeError_ptr*: pkSetRuntimeError.type
    pkGetSelf_ptr*: pkGetSelf.type
    pkGetArgc_ptr*: pkGetArgc.type
    pkCheckArgcRange_ptr*: pkCheckArgcRange.type
    pkValidateSlotBool_ptr*: pkValidateSlotBool.type
    pkValidateSlotNumber_ptr*: pkValidateSlotNumber.type
    pkValidateSlotInteger_ptr*: pkValidateSlotInteger.type
    pkValidateSlotString_ptr*: pkValidateSlotString.type
    pkValidateSlotType_ptr*: pkValidateSlotType.type
    pkValidateSlotInstanceOf_ptr*: pkValidateSlotInstanceOf.type
    pkIsSlotInstanceOf_ptr*: pkIsSlotInstanceOf.type
    pkReserveSlots_ptr*: pkReserveSlots.type
    pkGetSlotsCount_ptr*: pkGetSlotsCount.type
    pkGetSlotType_ptr*: pkGetSlotType.type
    pkGetSlotBool_ptr*: pkGetSlotBool.type
    pkGetSlotNumber_ptr*: pkGetSlotNumber.type
    pkGetSlotString_ptr*: pkGetSlotString.type
    pkGetSlotHandle_ptr*: pkGetSlotHandle.type
    pkGetSlotNativeInstance_ptr*: pkGetSlotNativeInstance.type
    pkSetSlotNull_ptr*: pkSetSlotNull.type
    pkSetSlotBool_ptr*: pkSetSlotBool.type
    pkSetSlotNumber_ptr*: pkSetSlotNumber.type
    pkSetSlotString_ptr*: pkSetSlotString.type
    pkSetSlotStringLength_ptr*: pkSetSlotStringLength.type
    pkSetSlotHandle_ptr*: pkSetSlotHandle.type
    pkGetSlotHash_ptr*: pkGetSlotHash.type
    pkPlaceSelf_ptr*: pkPlaceSelf.type
    pkGetClass_ptr*: pkGetClass.type
    pkNewInstance_ptr*: pkNewInstance.type
    pkNewRange_ptr*: pkNewRange.type
    pkNewList_ptr*: pkNewList.type
    pkNewMap_ptr*: pkNewMap.type
    pkListInsert_ptr*: pkListInsert.type
    pkListPop_ptr*: pkListPop.type
    pkListLength_ptr*: pkListLength.type
    pkCallFunction_ptr*: pkCallFunction.type
    pkCallMethod_ptr*: pkCallMethod.type
    pkGetAttribute_ptr*: pkGetAttribute.type
    pkSetAttribute_ptr*: pkSetAttribute.type
    pkImportModule_ptr*: pkImportModule.type

var pk_api*: PkNativeApi

proc pkInitApi(api: ptr PkNativeApi) {.cdecl, exportc, dynlib.} =
  pk_api = api[]

proc pkNewConfiguration*(): PkConfiguration =
  return pk_api.pkNewConfiguration_ptr()

proc pkNewVM*(config: ptr PkConfiguration): ptr PKVM =
  return pk_api.pkNewVM_ptr(config)

proc pkFreeVM*(vm: ptr PKVM) =
  pk_api.pkFreeVM_ptr(vm)

proc pkSetUserData*(vm: ptr PKVM; user_data: pointer) =
  pk_api.pkSetUserData_ptr(vm, user_data)

proc pkGetUserData*(vm: ptr PKVM): pointer =
  return pk_api.pkGetUserData_ptr(vm)

proc pkRegisterBuiltinFn*(vm: ptr PKVM; name: cstring; fn: pkNativeFn; arity: cint;
                         docstring: cstring) =
  pk_api.pkRegisterBuiltinFn_ptr(vm, name, fn, arity, docstring)

proc pkAddSearchPath*(vm: ptr PKVM; path: cstring) =
  pk_api.pkAddSearchPath_ptr(vm, path)

proc pkRealloc*(vm: ptr PKVM; `ptr`: pointer; size: csize_t): pointer =
  return pk_api.pkRealloc_ptr(vm, `ptr`, size)

proc pkReleaseHandle*(vm: ptr PKVM; handle: ptr PkHandle) =
  pk_api.pkReleaseHandle_ptr(vm, handle)

proc pkNewModule*(vm: ptr PKVM; name: cstring): ptr PkHandle =
  return pk_api.pkNewModule_ptr(vm, name)

proc pkRegisterModule*(vm: ptr PKVM; module: ptr PkHandle) =
  pk_api.pkRegisterModule_ptr(vm, module)

proc pkModuleAddFunction*(vm: ptr PKVM; module: ptr PkHandle; name: cstring;
                         fptr: pkNativeFn; arity: cint; docstring: cstring) =
  pk_api.pkModuleAddFunction_ptr(vm, module, name, fptr, arity, docstring)

proc pkNewClass*(vm: ptr PKVM; name: cstring; base_class: ptr PkHandle;
                module: ptr PkHandle; new_fn: pkNewInstanceFn;
                delete_fn: pkDeleteInstanceFn; docstring: cstring): ptr PkHandle =
  return pk_api.pkNewClass_ptr(vm, name, base_class, module, new_fn, delete_fn,
                              docstring)

proc pkClassAddMethod*(vm: ptr PKVM; cls: ptr PkHandle; name: cstring; fptr: pkNativeFn;
                      arity: cint; docstring: cstring) =
  pk_api.pkClassAddMethod_ptr(vm, cls, name, fptr, arity, docstring)

proc pkModuleAddSource*(vm: ptr PKVM; module: ptr PkHandle; source: cstring) =
  pk_api.pkModuleAddSource_ptr(vm, module, source)

proc pkRunString*(vm: ptr PKVM; source: cstring): PkResult =
  return pk_api.pkRunString_ptr(vm, source)

proc pkRunFile*(vm: ptr PKVM; path: cstring): PkResult =
  return pk_api.pkRunFile_ptr(vm, path)

proc pkRunREPL*(vm: ptr PKVM): PkResult =
  return pk_api.pkRunREPL_ptr(vm)

proc pkSetRuntimeError*(vm: ptr PKVM; message: cstring) =
  pk_api.pkSetRuntimeError_ptr(vm, message)

proc pkGetSelf*(vm: ptr PKVM): pointer =
  return pk_api.pkGetSelf_ptr(vm)

proc pkGetArgc*(vm: ptr PKVM): cint =
  return pk_api.pkGetArgc_ptr(vm)

proc pkCheckArgcRange*(vm: ptr PKVM; argc: cint; min: cint; max: cint): bool =
  return pk_api.pkCheckArgcRange_ptr(vm, argc, min, max)

proc pkValidateSlotBool*(vm: ptr PKVM; slot: cint; value: ptr bool): bool =
  return pk_api.pkValidateSlotBool_ptr(vm, slot, value)

proc pkValidateSlotNumber*(vm: ptr PKVM; slot: cint; value: ptr cdouble): bool =
  return pk_api.pkValidateSlotNumber_ptr(vm, slot, value)

proc pkValidateSlotInteger*(vm: ptr PKVM; slot: cint; value: ptr int32): bool =
  return pk_api.pkValidateSlotInteger_ptr(vm, slot, value)

proc pkValidateSlotString*(vm: ptr PKVM; slot: cint; value: ptr cstring;
                          length: ptr uint32): bool =
  return pk_api.pkValidateSlotString_ptr(vm, slot, value, length)

proc pkValidateSlotType*(vm: ptr PKVM; slot: cint; `type`: PkVarType): bool =
  return pk_api.pkValidateSlotType_ptr(vm, slot, `type`)

proc pkValidateSlotInstanceOf*(vm: ptr PKVM; slot: cint; cls: cint): bool =
  return pk_api.pkValidateSlotInstanceOf_ptr(vm, slot, cls)

proc pkIsSlotInstanceOf*(vm: ptr PKVM; inst: cint; cls: cint; val: ptr bool): bool =
  return pk_api.pkIsSlotInstanceOf_ptr(vm, inst, cls, val)

proc pkReserveSlots*(vm: ptr PKVM; count: cint) =
  pk_api.pkReserveSlots_ptr(vm, count)

proc pkGetSlotsCount*(vm: ptr PKVM): cint =
  return pk_api.pkGetSlotsCount_ptr(vm)

proc pkGetSlotType*(vm: ptr PKVM; index: cint): PkVarType =
  return pk_api.pkGetSlotType_ptr(vm, index)

proc pkGetSlotBool*(vm: ptr PKVM; index: cint): bool =
  return pk_api.pkGetSlotBool_ptr(vm, index)

proc pkGetSlotNumber*(vm: ptr PKVM; index: cint): cdouble =
  return pk_api.pkGetSlotNumber_ptr(vm, index)

proc pkGetSlotString*(vm: ptr PKVM; index: cint; length: ptr uint32): cstring =
  return pk_api.pkGetSlotString_ptr(vm, index, length)

proc pkGetSlotHandle*(vm: ptr PKVM; index: cint): ptr PkHandle =
  return pk_api.pkGetSlotHandle_ptr(vm, index)

proc pkGetSlotNativeInstance*(vm: ptr PKVM; index: cint): pointer =
  return pk_api.pkGetSlotNativeInstance_ptr(vm, index)

proc pkSetSlotNull*(vm: ptr PKVM; index: cint) =
  pk_api.pkSetSlotNull_ptr(vm, index)

proc pkSetSlotBool*(vm: ptr PKVM; index: cint; value: bool) =
  pk_api.pkSetSlotBool_ptr(vm, index, value)

proc pkSetSlotNumber*(vm: ptr PKVM; index: cint; value: cdouble) =
  pk_api.pkSetSlotNumber_ptr(vm, index, value)

proc pkSetSlotString*(vm: ptr PKVM; index: cint; value: cstring) =
  pk_api.pkSetSlotString_ptr(vm, index, value)

proc pkSetSlotStringLength*(vm: ptr PKVM; index: cint; value: cstring; length: uint32) =
  pk_api.pkSetSlotStringLength_ptr(vm, index, value, length)

proc pkSetSlotHandle*(vm: ptr PKVM; index: cint; handle: ptr PkHandle) =
  pk_api.pkSetSlotHandle_ptr(vm, index, handle)

proc pkGetSlotHash*(vm: ptr PKVM; index: cint): uint32 =
  return pk_api.pkGetSlotHash_ptr(vm, index)

proc pkPlaceSelf*(vm: ptr PKVM; index: cint) =
  pk_api.pkPlaceSelf_ptr(vm, index)

proc pkGetClass*(vm: ptr PKVM; instance: cint; index: cint) =
  pk_api.pkGetClass_ptr(vm, instance, index)

proc pkNewInstance*(vm: ptr PKVM; cls: cint; index: cint; argc: cint; argv: cint): bool =
  return pk_api.pkNewInstance_ptr(vm, cls, index, argc, argv)

proc pkNewRange*(vm: ptr PKVM; index: cint; first: cdouble; last: cdouble) =
  pk_api.pkNewRange_ptr(vm, index, first, last)

proc pkNewList*(vm: ptr PKVM; index: cint) =
  pk_api.pkNewList_ptr(vm, index)

proc pkNewMap*(vm: ptr PKVM; index: cint) =
  pk_api.pkNewMap_ptr(vm, index)

proc pkListInsert*(vm: ptr PKVM; list: cint; index: int32; value: cint): bool =
  return pk_api.pkListInsert_ptr(vm, list, index, value)

proc pkListPop*(vm: ptr PKVM; list: cint; index: int32; popped: cint): bool =
  return pk_api.pkListPop_ptr(vm, list, index, popped)

proc pkListLength*(vm: ptr PKVM; list: cint): uint32 =
  return pk_api.pkListLength_ptr(vm, list)

proc pkCallFunction*(vm: ptr PKVM; fn: cint; argc: cint; argv: cint; ret: cint): bool =
  return pk_api.pkCallFunction_ptr(vm, fn, argc, argv, ret)

proc pkCallMethod*(vm: ptr PKVM; instance: cint; `method`: cstring; argc: cint;
                  argv: cint; ret: cint): bool =
  return pk_api.pkCallMethod_ptr(vm, instance, `method`, argc, argv, ret)

proc pkGetAttribute*(vm: ptr PKVM; instance: cint; name: cstring; index: cint): bool =
  return pk_api.pkGetAttribute_ptr(vm, instance, name, index)

proc pkSetAttribute*(vm: ptr PKVM; instance: cint; name: cstring; value: cint): bool =
  return pk_api.pkSetAttribute_ptr(vm, instance, name, value)

proc pkImportModule*(vm: ptr PKVM; path: cstring; index: cint): bool =
  return pk_api.pkImportModule_ptr(vm, path, index)

when defined(windows):
  import winim/lean

  proc NimMain() {.cdecl, importc.}

  proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID) : BOOL {.stdcall, exportc, dynlib.} =
    NimMain()
    return true
