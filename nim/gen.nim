import npeg, strutils, strformat, tables

const PKHEADER = staticRead("../src/include/pocketlang.h")

type
  Pair = object
    name: string
    data: string

  Func = object
    name: string
    params: seq[Pair]
    ret: string

  Enum = object
    name: string
    items: seq[Pair]

  Definition = object
    fnptrs: seq[Func]
    fns: seq[Func]
    enums: seq[Enum]
    structs: OrderedTable[string, seq[Pair]]

proc typeToNim(typ: string): string =
  var ptrCount = typ.count('*')
  var typ = typ.replace("const").replace(" ").replace("*")

  case typ
  of "size_t", "double", "int":
    typ = "c" & typ

  of "int32_t", "uint32_t":
    typ.removeSuffix("_t")

  of "char":
    if ptrCount >= 1:
      ptrCount.dec
      typ = "cstring"

  of "void":
    if ptrCount >= 1:
      ptrCount.dec
      typ = "pointer"

  else: discard
  return "ptr ".repeat(ptrCount) & typ

proc nameEscape(name: string): string =
  case name
  of "from", "ptr", "type", "method":
    "`" & name & "`"
  else:
    name

proc paramsToNim(params: seq[Pair], nameOnly=false): string =
  for param in params:
    if param.name == "...": continue
    result.add nameEscape(param.name)
    if not nameOnly:
      result.add ": "
      result.add param.data
    result.add ", "
  result.removeSuffix(", ")

proc removeComment(code: string): string =
  let parser = peg("start", comments: seq[(string, string)]):
    start <- *@(comment1 | comment2 | comment3)
    comment1 <- "/*" * @"*/":
      comments.add ($0, "")

    comment2 <- "//" * @"\n":
      comments.add (($0)[0..^2], "")

    comment3 <- "#" * @"\n":
      comments.add (($0)[0..^2], "")

  var comments: seq[(string, string)]
  discard parser.match(code, comments)
  result = code.multiReplace(comments)

proc parse(code: string): Definition =
  var temp: seq[Pair]


  let parser = peg("start", def: Definition):
    start <- *@(obj | fnptr | fn | enu | stru)
    obj <- "typedef" * +Space * "struct" * +Space * >ident:
      def.structs[$1] = @[]

    fnptr <- "typedef" * +Space * >typ * *Space * "(*" * >ident * ")" * *Space * "(" * params * ")" :
      def.fnptrs.add Func(name: $2, params: temp, ret: typeToNim($1))
      temp = @[]

    fn <- "PK_PUBLIC" * +Space * >typ * +Space * >ident * *Space * "(" * params * ")":
      def.fns.add Func(name: $2, params: temp, ret: typeToNim($1))
      temp = @[]

    enu <- "enum" * +Space * >ident * *Space * "{" * *enuitem * *Space * "}":
      def.enums.add Enum(name: $1, items: temp)
      temp = @[]

    stru <- "struct" * +Space * >ident * *Space * "{" * *struitem * *Space * "}":
      def.structs[$1] = temp
      temp = @[]

    param <- (*Space * >typ * +Space * >ident * *Space) | *Space * >>("void*"|"...") * *Space:
      var name = $2
      if name == "void*": name = "a1"
      temp.add Pair(name: name, data: typeToNim($1))

    params <- *(param * ?(',' * *Space)) * *Space

    enuitem <- *Space * >ident * *Space * >?("=" * *Space * >+Digit) * *Space * ?',':
      temp.add Pair(name: $1, data: if $2 == "": "" else: $3)

    struitem <- *Space * >typ * +Space * >ident * *Space * ";":
      temp.add Pair(name: $2, data: typeToNim($1))

    typ <- ?("const" * +Space) * ident * *(*Space * '*')
    ident <- +{'A'..'Z','a'..'z','0'..'9', '_'}

  discard parser.match(code, result)

proc ident(n: int): string = "  ".repeat(n)

proc outputTypes(def: Definition, n = 0) =
  echo ident(n) & "type"
  for enu in def.enums:
    echo fmt"{ident(n+1)}{enu.name}* = enum"
    for item in enu.items:
      if item.data == "":
        echo fmt"{ident(n+2)}{item.name}"
      else:
        echo fmt"{ident(n+2)}{item.name} = {item.data}"

  for name, items in def.structs:
    echo fmt"{ident(n+1)}{name}* {{.bycopy.}} = object"
    for item in items:
      echo fmt"{ident(n+2)}{item.name}*: {item.data}"

  for fn in def.fnptrs:
    if fn.ret == "void":
      echo fmt"{ident(n+1)}{fn.name}* = proc ({paramsToNim(fn.params)}) {{.cdecl.}}"
    else:
      echo fmt"{ident(n+1)}{fn.name}* = proc ({paramsToNim(fn.params)}): {fn.ret} {{.cdecl.}}"

proc outputProcDef(def: Definition, n = 0) =
  for fn in def.fns:
    var ret = if fn.ret == "void": "" else: fmt": {fn.ret}"
    var pragma =
      if fn.params.len != 0 and fn.params[^1].name == "...": "{.importc, cdecl, varargs.}"
      else: "{.importc, cdecl.}"

    echo fmt"{ident(n)}proc {fn.name}*({paramsToNim(fn.params)}){ret} {pragma}"

proc outputModuleFile(def: Definition, n = 0) =
  echo ident(n) & "type"

  echo fmt"{ident(n+1)}PkNativeApi* {{.bycopy.}} = object"
  for fn in def.fns:
    if fn.params.len != 0 and fn.params[^1].name == "...": continue
    var ret = if fn.ret == "void": "" else: fmt": {fn.ret}"

    echo fmt"{ident(n+2)}{fn.name}*: proc ({paramsToNim(fn.params)}){ret} {{.cdecl.}}"

  echo fmt"{ident(n)}var pk_api*: PkNativeApi"
  echo fmt"{ident(n)}proc pkInitApi(api: ptr PkNativeApi) {{.cdecl, exportc, dynlib.}} = pk_api = api[]"

  for fn in def.fns:
    if fn.params.len != 0 and fn.params[^1].name == "...": continue
    var ret = if fn.ret == "void": "" else: fmt": {fn.ret}"
    echo fmt"{ident(n)}proc {fn.name}*({paramsToNim(fn.params)}){ret} = pk_api.{fn.name}({paramsToNim(fn.params, true)})"

  echo fmt"{ident(n)}when defined(windows) and not defined(gcDestructors):"
  echo fmt"{ident(n+1)}import winim/lean"
  echo fmt"{ident(n+1)}proc NimMain() {{.cdecl, importc.}}"
  echo fmt"{ident(n+1)}proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID) : BOOL {{.stdcall, exportc, dynlib.}} ="
  echo fmt"{ident(n+2)}NimMain()"
  echo fmt"{ident(n+2)}return true"

when isMainModule:
  var code = removeComment(PKHEADER)
  var def = code.parse()

  def.outputTypes(0)
  echo "when appType == \"lib\":"
  def.outputModuleFile(1)
  echo "else:"
  def.outputProcDef(1)
