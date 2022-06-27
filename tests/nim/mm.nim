import benchy

proc toString1(cstr: cstring, cstrlen: uint32): string =
  if cstr != nil and cstrlen != 0:
    result = newString(cstrlen)
    copyMem(addr result[0], cstr, cstrlen)

proc toString2(cstr: cstring, cstrlen: uint32): string =
  if cstr != nil and cstrlen != 0:
    result = newString(cstrlen)
    for i in 0..<cstrlen:
      result[i] = cstr[i]

var str = "a little string"
var cstr = cstring str

timeIt "toString1":
  for i in 0..10000:
    discard toString1(cstr, uint32 str.len)

timeIt "toString2":
  for i in 0..10000:
    discard toString2(cstr, uint32 str.len)