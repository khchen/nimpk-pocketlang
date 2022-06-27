# {.passL: "../lib/pocketlang.a".}

type
  PkVM* {.bycopy.} = object
    ## PocketLang Virtual Machine. It'll contain the state of the execution, stack,
    ## heap, and manage memory allocations.

  PkHandle* {.bycopy.} = object
    ## A handle to the pocketlang variables. It'll hold the reference to the
    ## variable and ensure that the variable it holds won't be garbage collected
    ## till it's released with pkReleaseHandle().

  pkNativeFn* = proc (vm: ptr PkVM) {.cdecl.}
    ##  C function pointer which is callable from pocketLang by native module
    ##  functions.

  pkReallocFn* = proc (memory: pointer; new_size: csize_t; user_data: pointer): pointer {.cdecl.}
    ##  A function that'll be called for all the allocation calls by PkVM.
    ##
    ##  - To allocate new memory it'll pass NULL to parameter [memory] and the
    ##    required size to [new_size]. On failure the return value would be NULL.
    ##
    ##  - When reallocating an existing memory if it's grow in place the return
    ##    address would be the same as [memory] otherwise a new address.
    ##
    ##  - To free an allocated memory pass [memory] and 0 to [new_size]. The
    ##    function will return NULL.

  pkWriteFn* = proc (vm: ptr PkVM; text: cstring) {.cdecl.}
    ##  Function callback to write [text] to stdout or stderr.

  pkReadFn* = proc (vm: ptr PkVM): cstring {.cdecl.}
    ##  A function callback to read a line from stdin. The returned string shouldn't
    ##  contain a line ending (\n or \r\n). The returned string **must** be
    ##  allocated with pkRealloc() and the VM will claim the ownership of the
    ##  string.

  pkSignalFn* = proc (a1: pointer) {.cdecl.}
    ##  A generic function thiat could be used by the PkVM to signal something to
    ##  the host application. The first argument is depend on the callback it's
    ##  registered.

  pkLoadScriptFn* = proc (vm: ptr PkVM; path: cstring): cstring {.cdecl.}
    ##  Load and return the script. Called by the compiler to fetch initial source
    ##  code and source for import statements. Return NULL to indicate failure to
    ##  load. Otherwise the string **must** be allocated with pkRealloc() and
    ##  the VM will claim the ownership of the string.

  pkLoadDL* = proc (vm: ptr PkVM; path: cstring): pointer {.cdecl.}
    ##  Load and return the native extension (*.dll, *.so) from the path, this will
    ##  then used to import the module with the pkImportImportDL function. On error
    ##  the function should return NULL and shouldn't use any error api function.

  pkImportDL* = proc (vm: ptr PkVM; handle: pointer): ptr PkHandle {.cdecl.}
    ##  Native extension loader from the dynamic library. The handle should be vaiid
    ##  as long as the module handle is alive. On error the function should return
    ##  NULL and shouldn't use any error api function.

  pkUnloadDL* = proc (vm: ptr PkVM; handle: pointer) {.cdecl.}
    ##  Once the native module is gargage collected, the dl handle will be released
    ##  with pkUnloadDL function.

  pkResolvePathFn* = proc (vm: ptr PkVM; `from`: cstring; path: cstring): cstring {.cdecl.}
    ##  A function callback to resolve the import statement path. [from] path can
    ##  be either path to a script or a directory or NULL if [path] is relative to
    ##  cwd. If the path is a directory it'll always ends with a path separator
    ##  which could be either '/' or '\\' regardless of the system. Since pocketlang is
    ##  un aware of the system, to indicate that the path is a directory.
    ##
    ##  The return value should be a normalized absolute path of the [path]. Return
    ##  NULL to indicate failure to resolve. Othrewise the string **must** be
    ##  allocated with pkRealloc() and the VM will claim the ownership of the
    ##  string.

  pkNewInstanceFn* = proc (vm: ptr PkVM): pointer {.cdecl.}
    ##  A function callback to allocate and return a new instance of the registered
    ##  class. Which will be called when the instance is constructed. The returned/
    ##  data is expected to be alive till the delete callback occurs.

  pkDeleteInstanceFn* = proc (vm: ptr PkVM; a2: pointer) {.cdecl.}
    ##  A function callback to de-allocate the allocated native instance of the
    ##  registered class. This function is invoked at the GC execution. No object
    ##  allocations are allowed during it, so **NEVER** allocate any objects
    ##  inside them.

  PkVarType* = enum
    PK_OBJECT = 0, PK_NULL, PK_BOOL, PK_NUMBER, PK_STRING, PK_LIST, PK_MAP, PK_RANGE,
    PK_MODULE, PK_CLOSURE, PK_METHOD_BIND, PK_FIBER, PK_CLASS, PK_INSTANCE
    ##  Type enum of the pocketlang's first class types. Note that Object isn't
    ##  instanciable (as of now) but they're considered first calss.

  PkResult* = enum
    ##  Result that pocketlang will return after a compilation or running a script
    ##  or a function or evaluating an expression.
    PK_RESULT_SUCCESS = 0, ##  Successfully finished the execution.
                        ##  Note that this result is internal and will not be returned to the host
                        ##  anymore.
                        ##
                        ##  Unexpected EOF while compiling the source. This is another compile time
                        ##  error that will ONLY be returned if we're compiling in REPL mode. We need
                        ##  this specific error to indicate the host application to add another line
                        ##  to the last input. If REPL is not enabled this will be compile error.
    PK_RESULT_UNEXPECTED_EOF,
    PK_RESULT_COMPILE_ERROR, ##  Compilation failed.
    PK_RESULT_RUNTIME_ERROR   ##  An error occurred at runtime.

  PkConfiguration* {.bycopy.} = object
    realloc_fn*: pkReallocFn ##  The callback used to allocate, reallocate, and free. If the function
                           ##  pointer is NULL it defaults to the VM's realloc(), free() wrappers.
    ##  I/O callbacks.
    stderr_write*: pkWriteFn
    stdout_write*: pkWriteFn
    stdin_read*: pkReadFn      ##  Import system callbacks.
    resolve_path_fn*: pkResolvePathFn
    load_script_fn*: pkLoadScriptFn
    load_dl_fn*: pkLoadDL
    import_dl_fn*: pkImportDL
    unload_dl_fn*: pkUnloadDL  ##  If true stderr calls will use ansi color codes.
    use_ansi_escape*: bool     ##  User defined data associated with VM.
    user_data*: pointer

{.push importc, cdecl.}

proc pkNewConfiguration*(): PkConfiguration
  ##  Create a new PkConfiguration with the default values and return it.
  ##  Override those default configuration to adopt to another hosting
  ##  application.

proc pkNewVM*(config: ptr PkConfiguration): ptr PkVM
  ##  Allocate, initialize and returns a new VM.

proc pkFreeVM*(vm: ptr PkVM)
  ##  Clean the VM and dispose all the resources allocated by the VM.

proc pkSetUserData*(vm: ptr PkVM; user_data: pointer)
  ##  Update the user data of the vm.

proc pkGetUserData*(vm: ptr PkVM): pointer
  ##  Returns the associated user data.

proc pkRegisterBuiltinFn*(vm: ptr PkVM; name: cstring; fn: pkNativeFn; arity: cint;
                         docstring: cstring)
  ##  Register a new builtin function with the given [name]. [docstring] could be
  ##  NULL or will always valid pointer since PkVM doesn't allocate a string for
  ##  docstrings.

proc pkAddSearchPath*(vm: ptr PkVM; path: cstring)
  ##  Adds a new search paht to the VM, the path will be appended to the list of
  ##  search paths. Search path orders are the same as the registered order.
  ##  the last character of the path **must** be a path seperator '/' or '\\'.

proc pkRealloc*(vm: ptr PkVM; `ptr`: pointer; size: csize_t): pointer
  ##  Invoke pocketlang's allocator directly.  This function should be called
  ##  when the host application want to send strings to the PkVM that are claimed
  ##  by the VM once the caller returned it. For other uses you **should** call
  ##  pkRealloc with [size] 0 to cleanup, otherwise there will be a memory leak.
  ##
  ##  Internally it'll call `pkReallocFn` function that was provided in the
  ##  configuration.

proc pkReleaseHandle*(vm: ptr PkVM; handle: ptr PkHandle)
  ##  Release the handle and allow its value to be garbage collected. Always call
  ##  this for every handles before freeing the VM.

proc pkNewModule*(vm: ptr PkVM; name: cstring): ptr PkHandle
  ##  Add a new module named [name] to the [vm]. Note that the module shouldn't
  ##  already existed, otherwise an assertion will fail to indicate that.

proc pkRegisterModule*(vm: ptr PkVM; module: ptr PkHandle)
  ##  Register the module to the PkVM's modules map, once after it can be
  ##  imported in other modules.

proc pkModuleAddFunction*(vm: ptr PkVM; module: ptr PkHandle; name: cstring;
                         fptr: pkNativeFn; arity: cint; docstring: cstring)
  ##  Add a native function to the given module. If [arity] is -1 that means
  ##  the function has variadic parameters and use pkGetArgc() to get the argc.
  ##  Note that the function will be added as a global variable of the module.
  ##  [docstring] is optional and could be omitted with NULL.

proc pkNewClass*(vm: ptr PkVM; name: cstring; base_class: ptr PkHandle;
                module: ptr PkHandle; new_fn: pkNewInstanceFn;
                delete_fn: pkDeleteInstanceFn; docstring: cstring): ptr PkHandle
  ##  Create a new class on the [module] with the [name] and return it.
  ##  If the [base_class] is NULL by default it'll set to "Object" class.
  ##  [docstring] is optional and could be omitted with NULL.

proc pkClassAddMethod*(vm: ptr PkVM; cls: ptr PkHandle; name: cstring; fptr: pkNativeFn;
                      arity: cint; docstring: cstring)
  ##  Add a native method to the given class. If the [arity] is -1 that means
  ##  the method has variadic parameters and use pkGetArgc() to get the argc.
  ##  [docstring] is optional and could be omitted with NULL.

proc pkModuleAddSource*(vm: ptr PkVM; module: ptr PkHandle; source: cstring)
  ##  It'll compile the pocket [source] for the module which result all the
  ##  functions and classes in that [source] to register on the module.

proc pkRunString*(vm: ptr PkVM; source: cstring): PkResult
  ##  Run the source string. The [source] is expected to be valid till this
  ##  function returns.

proc pkRunFile*(vm: ptr PkVM; path: cstring): PkResult
  ##  Run the file at [path] relative to the current working directory.

proc pkRunREPL*(vm: ptr PkVM): PkResult
  ##  FIXME:
  ##  Currently exit function will terminate the process which should exit from
  ##  the function and return to the caller.
  ##
  ##  Run pocketlang REPL mode. If there isn't any stdin read function defined,
  ##  or imput function ruturned NULL, it'll immediatly return a runtime error.

proc pkSetRuntimeError*(vm: ptr PkVM; message: cstring)
  ##  Set a runtime error to VM.

proc pkSetRuntimeErrorFmt*(vm: ptr PkVM; fmt: cstring) {.varargs.}
  ##  Set a runtime error with C formated string.

proc pkGetSelf*(vm: ptr PkVM): pointer
  ##  Returns native [self] of the current method as a void*.

proc pkGetArgc*(vm: ptr PkVM): cint
  ##  Return the current functions argument count. This is needed for functions
  ##  registered with -1 argument count (which means variadic arguments).

proc pkCheckArgcRange*(vm: ptr PkVM; argc: cint; min: cint; max: cint): bool
  ##  Check if the argc is in the range of (min <= argc <= max), if it's not, a
  ##  runtime error will be set and return false, otherwise return true. Assuming
  ##  that min <= max, and pocketlang won't validate this in release binary.

proc pkValidateSlotBool*(vm: ptr PkVM; slot: cint; value: ptr bool): bool
  ##  Helper function to check if the argument at the [slot] slot is Boolean and
  ##  if not set a runtime error.

proc pkValidateSlotNumber*(vm: ptr PkVM; slot: cint; value: ptr cdouble): bool
  ##  Helper function to check if the argument at the [slot] slot is Number and
  ##  if not set a runtime error.

proc pkValidateSlotInteger*(vm: ptr PkVM; slot: cint; value: ptr int32): bool
  ##  Helper function to check if the argument at the [slot] is an a whold number
  ##  and if not set a runtime error.

proc pkValidateSlotString*(vm: ptr PkVM; slot: cint; value: ptr cstring;
                          length: ptr uint32): bool
  ##  Helper function to check if the argument at the [slot] slot is String and
  ##  if not set a runtime error.

proc pkValidateSlotType*(vm: ptr PkVM; slot: cint; `type`: PkVarType): bool
  ##  Helper function to check if the argument at the [slot] slot is of type
  ##  [type] and if not sets a runtime error.

proc pkValidateSlotInstanceOf*(vm: ptr PkVM; slot: cint; cls: cint): bool
  ##  Helper function to check if the argument at the [slot] slot is an instance
  ##  of the class which is at the [cls] index. If not set a runtime error.

proc pkIsSlotInstanceOf*(vm: ptr PkVM; inst: cint; cls: cint; val: ptr bool): bool
  ##  Helper function to check if the instance at the [inst] slot is an instance
  ##  of the class which is at the [cls] index. The value will be set to [val]
  ##  if the object at [cls] slot isn't a valid class a runtime error will be set
  ##  and return false.

proc pkReserveSlots*(vm: ptr PkVM; count: cint)
  ##  Make sure the fiber has [count] number of slots to work with (including the
  ##  arguments).

proc pkGetSlotsCount*(vm: ptr PkVM): cint
  ##  Returns the available number of slots to work with. It has at least the
  ##  number argument the function is registered plus one for return value.

proc pkGetSlotType*(vm: ptr PkVM; index: cint): PkVarType
  ##  Returns the type of the variable at the [index] slot.

proc pkGetSlotBool*(vm: ptr PkVM; index: cint): bool
  ##  Returns boolean value at the [index] slot. If the value at the [index]
  ##  is not a boolean it'll be casted (only for booleans).

proc pkGetSlotNumber*(vm: ptr PkVM; index: cint): cdouble
  ##  Returns number value at the [index] slot. If the value at the [index]
  ##  is not a boolean, an assertion will fail.

proc pkGetSlotString*(vm: ptr PkVM; index: cint; length: ptr uint32): cstring
  ##  Returns the string at the [index] slot. The returned pointer is only valid
  ##  inside the native function that called this. Afterwards it may garbage
  ##  collected and become demangled. If the [length] is not NULL the length of
  ##  the string will be written.

proc pkGetSlotHandle*(vm: ptr PkVM; index: cint): ptr PkHandle
  ##  Capture the variable at the [index] slot and return its handle. As long as
  ##  the handle is not released with `pkReleaseHandle()` the variable won't be
  ##  garbage collected.

proc pkGetSlotNativeInstance*(vm: ptr PkVM; index: cint): pointer
  ##  Returns the native instance at the [index] slot. If the value at the [index]
  ##  is not a valid native instance, an assertion will fail.

proc pkSetSlotNull*(vm: ptr PkVM; index: cint)
  ##  Set the [index] slot value as pocketlang null.

proc pkSetSlotBool*(vm: ptr PkVM; index: cint; value: bool)
  ##  Set the [index] slot boolean value as the given [value].

proc pkSetSlotNumber*(vm: ptr PkVM; index: cint; value: cdouble)
  ##  Set the [index] slot numeric value as the given [value].

proc pkSetSlotString*(vm: ptr PkVM; index: cint; value: cstring)
  ##  Create a new String copying the [value] and set it to [index] slot.

proc pkSetSlotStringLength*(vm: ptr PkVM; index: cint; value: cstring; length: uint32)
  ##  Create a new String copying the [value] and set it to [index] slot. Unlike
  ##  the above function it'll copy only the spicified length.

proc pkSetSlotStringFmt*(vm: ptr PkVM; index: cint; fmt: cstring) {.varargs.}
  ##  Create a new string copying from the formated string and set it to [index]
  ##  slot.

proc pkSetSlotHandle*(vm: ptr PkVM; index: cint; handle: ptr PkHandle)
  ##  Set the [index] slot's value as the given [handle]. The function won't
  ##  reclaim the ownership of the handle and you can still use it till
  ##  it's released by yourself.

proc pkGetSlotHash*(vm: ptr PkVM; index: cint): uint32
  ##  Returns the hash of the [index] slot value. The value at the [index] must be
  ##  hashable.

proc pkPlaceSelf*(vm: ptr PkVM; index: cint)
  ##  Place the [self] instance at the [index] slot.

proc pkGetClass*(vm: ptr PkVM; instance: cint; index: cint)
  ##  Set the [index] slot's value as the class of the [instance].

proc pkNewInstance*(vm: ptr PkVM; cls: cint; index: cint; argc: cint; argv: cint): bool
  ##  Creates a new instance of class at the [cls] slot, calls the constructor,
  ##  and place it at the [index] slot. Returns true if the instance constructed
  ##  successfully.
  ##
  ##  [argc] is the argument count for the constructor, and [argv]
  ##  is the first argument slot's index.

proc pkNewRange*(vm: ptr PkVM; index: cint; first: cdouble; last: cdouble)
  ##  Create a new Range object and place it at [index] slot.

proc pkNewList*(vm: ptr PkVM; index: cint)
  ##  Create a new List object and place it at [index] slot.

proc pkNewMap*(vm: ptr PkVM; index: cint)
  ##  Create a new Map object and place it at [index] slot.

proc pkListInsert*(vm: ptr PkVM; list: cint; index: int32; value: cint): bool
  ##  Insert [value] to the [list] at the [index], if the index is less than zero,
  ##  it'll count from backwards. ie. insert[-1] == insert[list.length].
  ##  Note that slot [list] must be a valid list otherwise it'll fail an
  ##  assertion.

proc pkListPop*(vm: ptr PkVM; list: cint; index: int32; popped: cint): bool
  ##  Pop an element from [list] at [index] and place it at the [popped] slot, if
  ##  [popped] is negative, the popped value will be ignored.

proc pkListLength*(vm: ptr PkVM; list: cint): uint32
  ##  Returns the length of the list at the [list] slot, it the slot isn't a list
  ##  an assertion will fail.

proc pkCallFunction*(vm: ptr PkVM; fn: cint; argc: cint; argv: cint; ret: cint): bool
  ##  Calls a function at the [fn] slot, with [argc] argument where [argv] is the
  ##  slot of the first argument. [ret] is the slot index of the return value. if
  ##  [ret] < 0 the return value will be discarded.

proc pkCallMethod*(vm: ptr PkVM; instance: cint; `method`: cstring; argc: cint;
                  argv: cint; ret: cint): bool
  ##  Calls a [method] on the [instance] with [argc] argument where [argv] is the
  ##  slot of the first argument. [ret] is the slot index of the return value. if
  ##  [ret] < 0 the return value will be discarded.

proc pkGetAttribute*(vm: ptr PkVM; instance: cint; name: cstring; index: cint): bool
  ##  Get the attribute with [name] of the instance at the [instance] slot and
  ##  place it at the [index] slot. Return true on success.

proc pkSetAttribute*(vm: ptr PkVM; instance: cint; name: cstring; value: cint): bool
  ##  Set the attribute with [name] of the instance at the [instance] slot to
  ##  the value at the [value] index slot. Return true on success.

proc pkImportModule*(vm: ptr PkVM; path: cstring; index: cint): bool
  ##  Import a module with the [path] and place it at [index] slot. The path
  ##  sepearation should be '/'. Example: to import module "foo.bar" the [path]
  ##  should be "foo/bar". On failure, it'll set an error and return false.

{.pop.}

when isMainModule:
  var vm = pkNewVM(nil)
  discard vm.pkRunString """
    print("Hello, world!")
  """
  vm.pkFreeVM()
