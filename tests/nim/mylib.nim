import pknative

proc hello(vm: ptr PkVM) {.cdecl.} =
  vm.pkSetSlotString(0, "hello from dynamic lib by nim.")

proc pkExportModule(vm: ptr PkVM): ptr PkHandle {.cdecl, exportc, dynlib.} =
  var mylib = vm.pkNewModule("mylib")
  vm.pkModuleAddFunction(mylib, "hello", hello, 0, nil)

  return mylib
