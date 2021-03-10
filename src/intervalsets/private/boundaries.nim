type
  BoundaryKind = enum
    Below
    Above

  Boundary*[V] = object
    ## A Boundary is a division of an ordered type into values above and below the boundary. No value can sit on a boundary.
    v*: V
    kind: BoundaryKind

func adjacient*[T](a,b: T): bool =
  ## True if `b` is the next ordinal value after `a`
  runnableExamples:
    assert adjacient(0, 1)
    assert not adjacient(0, 2)
    assert not adjacient(0.0, 1.1)
  when T is Ordinal:
    ord(a)+1 == ord(b)
  else: false

func below*[V](v: V): Boundary[V] =
  ## Constructs a boundary immediately below `v`
  Boundary[V](v: v, kind: Below)

func above*[V](v: V): Boundary[V] =
  ## Constructs a boundary immediately above `v`
  Boundary[V](v: v, kind: Above)

func cmp*[V](a, b: Boundary[V]): int =
  ## Comparison operator for boundaries
  case a.kind
  of Below:
    case b.kind
    of Below: cmp(a.v, b.v)
    of Above:
      if a.v > b.v:
        if adjacient(b.v, a.v): 0
        else: 1
      else: -1
  of Above:
    case b.kind
    of Above: cmp(a.v, b.v)
    of Below:
      if a.v < b.v:
        if adjacient(a.v, b.v): 0
        else: -1
      else: 1

func valueAbove*[V](b: Boundary[V]): V =
  ## The value above `b`
  ##
  ## Note: This raises an error if `b` is above some non-ordinal or above `high(V)`.
  runnableExamples:
    assert valueAbove(below(0)) == 0
    assert valueAbove(above(0)) == 1
  case b.kind
  of Below: b.v
  of Above:
    when V is Ordinal:
      succ(b.v)
    else:
      raise newException(ValueError, "value above non-ordinal is undefined")

func valueBelow*[V](b: Boundary[V]): V =
  ## The value below `b`
  ##
  ## Note: This raises an error if `b` is below some non-ordinal or below `low(V)`.
  runnableExamples:
    assert valueBelow(above(0)) == 0
    assert valueBelow(below(1)) == 0
  case b.kind
  of Above: b.v
  of Below:
    when V is Ordinal:
      pred(b.v)
    else:
      raise newException(ValueError, "value below non-ordinal is undefined")

func `<`*[V](a, b: Boundary[V]): bool {.inline.} = cmp(a,b) < 0
func `>`*[V](a, b: Boundary[V]): bool {.inline.} = cmp(a,b) > 0
func `==`*[V](a, b: Boundary[V]): bool {.inline.} = cmp(a,b) == 0
func `<=`*[V](a, b: Boundary[V]): bool {.inline.} = cmp(a,b) <= 0
func `>=`*[V](a, b: Boundary[V]): bool {.inline.} = cmp(a,b) >= 0

func `<`*[V](a: Boundary[V], v: V): bool {.inline.} =
  ## True if `a` is below `v`
  case a.kind
  of Below:
    a.v <= v
  of Above:
    a.v < v

func `<`*[V](v: V, a: Boundary[V]): bool {.inline.} =
  ## True if `v` is below `b`
  case a.kind
  of Below:
    v < a.v
  of Above:
    v <= a.v
