include private/boundaries
import hashes

type
  Interval*[V:not Ordinal] = object
    ## A range of values marked by `upper` and `lower` boundaries.
    lower: Boundary[V]
    upper: Boundary[V]

  OrdinalInterval*[V:Ordinal] = Slice[V]
    ## A specialization of `Interval` for ordinal types

  SomeInterval*[V] = Interval[V] | OrdinalInterval[V]

template emptyInterval*(V:typedesc): untyped =
  when V is Ordinal:
    succ(default(V)) .. default(V)
  else:
    Interval[V](lower: above(default(V)), upper: below(default(V)))

func a*[V](i: Interval[V]): V {.inline.} =
  ## The value above `i`'s lower boundary, if it can be determined.
  valueAbove(i.lower)

func b*[V](i: Interval[V]): V {.inline.} =
  ## The value below `i`'s upper boundary, if it can be determined.
  valueBelow(i.upper)

func lower*[V](i: SomeInterval[V]): auto {.inline.} =
  ## The lower boundary of `i`
  when i is Interval:
    i.lower
  else:
    below(i.a)

func upper*[V](i: SomeInterval[V]): auto {.inline.} =
  ## The upper boundary of `i`
  when i is Interval:
    i.upper
  else:
    above(i.b)

func len*[V:Ordinal](i: Interval[V]): int =
  ## The length of `i`, only defined for ordinal types.
  len(i.a .. i.b)

func isEmpty*[V](i: SomeInterval[V]): bool =
  ## True if `i`'s upper bound is less than or equal to its lower bound.
  when type(i) is Interval:
    i.upper <= i.lower
  else:
    i.a > i.b

proc hash*(i: SomeInterval): Hash =
  result = result !& hash(i.lower.kind)
  result = result !& hash(i.lower.v)
  result = result !& hash(i.lower.kind)
  result = result !& hash(i.upper.v)
  result = !$result

func openBelow*(i: SomeInterval): bool =
  ## True if `i` does not include its lower value.
  when i is Interval:
    i.lower.kind == Above
  else: false

func openAbove*(i: SomeInterval): bool =
  ## True if `i` does not include its upper value.
  when i is Interval:
    i.upper.kind == Below
  else: false

func open*(i: SomeInterval): bool =
  ## True if `i` is open both below and above.
  openBelow(i) and openAbove(i)

template closedBelow*(i: SomeInterval): bool =
  ## True if `i` includes its lower value.
  not openBelow(i)

template closedAbove*(i: SomeInterval): bool =
  ## True if `i` includes its upper value.
  not openAbove(i)

template closed*(i: SomeInterval): bool =
  ## True if `i` is closed both below and above.
  closedBelow(i) and closedAbove(i)

template singleton*[V](i: SomeInterval[V]): bool =
  ## True if `i` contains a single value.
  when V is Ordinal:
    i.a == i.b
  else:
    closed(i) and i.lower.v == i.upper.v

func contains*[V](i: Interval[V], v: V): bool =
  ## True if `v` lies in `i`.
  i.lower < v and v < i.upper

func contains*[V](a: Interval[V], b: SomeInterval[V]): bool =
  ## True if `a` encloses `b`.
  if a.isEmpty or b.isEmpty: false
  else: a.lower <= b.lower and b.upper <= a.upper

func contains*[V:Ordinal](a,b: Slice[V]): bool =
  a.a <= b.a and b.b <= a.b

func `<`*[A:SomeInterval,B:SomeInterval](a: A, b: B): bool =
  if a.isEmpty: true
  elif b.isEmpty: false
  else:
    a.lower < b.lower or
    a.lower == b.lower and a.upper < b.upper

func `..`*[V: not Ordinal](l, u: Boundary[V]): auto =
  ## Constructs an interval from boundaries `l` and `u`.
  Interval[V](lower: l, upper: u)

func `..`*[V:Ordinal](l, u: Boundary[V]): auto =
  valueAbove(l) .. valueBelow(u)

func `<=..` *[V](l: V, u: Boundary[V]): auto =
  ## Constructs an interval with a boundary below `l` and upper boundary `u`.
  below(l) .. u

func `<..`  *[V](l: V, u: Boundary[V]): auto =
  ## Constructs an interval with a boundary above `l` and upper boundary `u`.
  above(l) .. u

func `..`   *[V](l: Boundary[V], u: V): auto =
  ## Constructs an interval with lower boundary `l` and a boundary above `u`.
  l .. above(u)

func `..<`  *[V](l: Boundary[V], u: V): auto =
  ## Constructs an interval with lower boundary `l` and a boundary below `u`.
  l .. below(u)

func `<=..` *[V](l,u: V): auto =
  ## Constructs an interval with a boundary below `l` and a boundary above `u`.
  below(l) .. above(u)

func `<=..<`*[V](l,u: V): auto =
  ## Constructs an interval with a boundary below `l` and a boundary below `u`.
  below(l) .. below(u)

func `<..<` *[V](l,u: V): auto =
  ## Constructs an interval with a boundary above `l` and a boundary below `u`.
  above(l) .. below(u)

func `<..`  *[V](l,u: V): auto =
  ## Constructs an interval with a boundary above `l` and a boundary above `u`.
  above(l) .. above(u)

func `..` *[V](l: V, u: Boundary[V]): auto =
  ## Same as `l <= u`.
  l <=.. u

func overlap*[V](a, b: Interval[V]): bool =
  ## True if `a.upper >= b.lower`
  a.upper >= b.lower

func difference*[V](a,b: Interval[V]): auto =
  ## Computes a - b.
  ##
  ## Returns an array of length 2, the first element being the part of `a` below `b`,
  ## the second the part of `a` above `b` respective. If both elements are empty, `a` is contained in `b`
  [a.lower .. b.lower, b.upper .. a.upper]

func intersection*[V](a,b: Interval[V]): auto =
  ## Computes the interval of all values both in `a` and `b`.
  max(a.lower, b.lower)..min(a.upper, b.upper)

func extent*[V](a,b: Interval[V]): auto =
  ## Computes the interval of all values between `a` and `b`.
  min(a.lower, b.lower)..max(a.upper, b.upper)

func overlap*[V:Ordinal](a,b: Slice[V]): bool =
  a.b >= b.a or adjacient(a.b, b.a)

func intersection*[V:Ordinal](a,b: Slice[V]): auto =
  max(a.a, b.a)..min(a.b, b.b)

func difference*[V:Ordinal](a,b: Slice[V]): auto =
  [
    if b.a == low(V): emptyInterval(V)
    else: a.a .. pred(b.a),
    if b.b == high(V): emptyInterval(V)
    else: succ(b.b) .. a.b
  ]

func extent*[V:Ordinal](a,b: Slice[V]): auto =
  min(a.a, b.a)..max(a.b, b.b)

func `$`*[V](i: Interval[V]): string =
  result.add $i.lower.v
  if not singleton(i):
    result.add ' '
    if openBelow(i): result.add '<'
    result.add ".."
    if openAbove(i): result.add '<'
    result.add ' '
    result.add $i.upper.v
