# import pegs

# var cap: seq[string]
# cap.setLen(100)

# # var peg = peg"{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}{\d}"
# # echo peg
# # echo match("123123123123123123123123123123123", peg, cap)
# # echo cap

# var peg = peg"{\d}\w"
# echo find("....1a,2b,3c,4d", peg, cap)
# echo cap

# echo findAll("....1a2b3c4d", peg)
# echo split("....1a,2b,3c,4d", peg)

import std/[strutils, pegs]

type
  Node = ref object
    name: string
    slice: Slice[int]
    head: Node
    tail: Node
    next: Node

var peg = peg("""
    Expr    <- Sum
    Sum     <- Product ((Add / Minus)Product)*
    Product <- Value ((Mul / Div)Value)*
    Value   <- Integer / '(' Sum ')'

    Add     <- '+'
    Minus   <- '-'
    Mul     <- '*'
    Div     <- '/'
    Integer <- [0-9]+
  """)


var txt = "(5+3)/(2-7)*22"
txt = "1+2+3+4"

var
  root = Node(name: "@root")
  nodeStack: seq[Node] = @[]

let
  parseArithExpr = peg.eventParser:
    pkNonTerminal:
      enter:
        nodeStack.add Node(name: p.nt.name)

      leave:
        var node = nodeStack.pop()
        if length != -1:
          var parent: Node
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

var n = parseArithExpr(txt)

if n > 0:
  root.slice = 0..<n
  proc debug(node: Node, indent = 0) =
    var node = node
    while node != nil:
      echo " ".repeat indent, node.name, ": ", txt[node.slice]

      if node.head != nil:
        debug(node.head, indent + 2)
      node = node.next

  debug(root)
