## The `intervalsets` module implements a set of ordered disjoin intervals,
## allowing to efficiently store large ranges of values as opposed to a sparse set.
##
## .. code-block::
##   echo toIntervalSet({'A'..'Z', 'a'..'z'}) # {'A'..'Z', 'a'..'z'}
##   echo toIntervalSet([0..0, 2..4, 5..6]) # {0, 2..6}
##
## The Implementation is inspired by the `RangedSet Haskell Type
## <https://hackage.haskell.org/package/Ranged-sets>`_

import algorithm, hashes, sequtils
import intervalsets/intervals
export intervals

type IntervalSet*[V] = object
  ## An ordered collection of disjoint intervals
  when V is Ordinal:
    intervals: seq[OrdinalInterval[V]]
  else:
    intervals: seq[Interval[V]]

func `==`*[V](a,b: IntervalSet[V]): bool =
  if len(a.intervals) == len(b.intervals):
    for i in 0..<len(a.intervals):
      if a.intervals[i] != b.intervals[i]: return false
    true
  else:
    false

proc hash*(s: IntervalSet): Hash =
  for iv in s.intervals:
    result = result !& hash(iv)
  result = !$result

func countIntervals*(s: IntervalSet): int = len(s.intervals)
func getInterval*(s: IntervalSet, i: int): auto = s.intervals[i]
func getInterval*(s: IntervalSet, i: BackwardsIndex): auto = s.intervals[i]

iterator intervals1[V,U](s: set[V]): Slice[U] =
  var iv = 0.. -1
  for i in s:
    if len(iv) == 0:
      iv = ord(i)..ord(i)
    elif ord(i) in iv: continue
    elif adjacient(iv.b, ord(i)):
      inc(iv.b)
    else:
      yield U(iv.a)..U(iv.b)
      iv = ord(i)..ord(i)
  if len(iv) != 0:
    yield U(iv.a)..U(iv.b)

iterator intervals[V](s: set[V]): auto =
  for i in intervals1[V,V](s):
    yield i

iterator intervals*[V](s: IntervalSet[V]): auto =
  ## Iterates over the intervals of `s`.
  for i in s.intervals:
    yield i

iterator items*[V:Ordinal](s: IntervalSet[V]): V =
  ## Iterates over every value in every interval of `s`.
  ##
  ## This is only defined for ordinal types.
  for iv in s.intervals:
    for i in iv: yield i

func len*[V:Ordinal](s: IntervalSet[V]): int =
  ## The number of ordinal values in `s`
  for iv in s.intervals:
    result += len(iv)

proc `$`*[V](s: IntervalSet[V]): string =
  result = "{"
  for i in s.intervals:
    if result.len > 1: result.add ", "
    result.addQuoted i.lower.v
    if not singleton(i):
      result.add(' ')
      if openBelow(i): result.add('<')
      result.add ".."
      if openAbove(i): result.add('<')
      result.add(' ')
      result.addQuoted i.upper.v
  result.add '}'

proc normalize[V](s: var seq[SomeInterval[V]], range: Slice[int]) =
  var i = range.a
  var j = range.b
  while i < j:
    template a: auto = s[i]
    template b: auto = s[i+1]
    if overlap(a, b):
      a = extent(a, b)
      delete(s, i+1)
      dec j
    else:
      inc i

proc normalize[V](s: var seq[SomeInterval[V]]) = normalize(s, s.low .. s.high)

proc isEmpty*(s: IntervalSet): bool = s.intervals.len == 0

proc toIntervalSet*[V:Ordinal](a: openArray[Slice[V]]): IntervalSet[V] =
  ## Construct an interval set from an array of intervals.
  ##
  ## Intervals are sorted and overlaps are merged.
  runnableExamples:
    import sequtils
    let s = toIntervalSet([1..3, 2..4, 0..0])
    assert toSeq(s.intervals) == [0..4]
  result.intervals = a.filterIt(not it.isEmpty)
  sort(result.intervals)
  normalize(result.intervals)

proc toIntervalSet*[V:Ordinal](a: openArray[V]): IntervalSet[V] =
  ## Construct an interval set from an array of values.
  result.intervals = a.mapIt(it..it)
  sort(result.intervals)
  normalize(result.intervals)

proc toIntervalSet*[V:not Ordinal](a: openArray[SomeInterval[V]]): IntervalSet[V] =
  ## Construct an interval set from an array of intervals.
  ##
  ## Intervals are sorted and overlaps are merged.
  runnableExamples:
    import sequtils
    let s = toIntervalSet([1.0<=..3.0, 2.0<=..4.0, 0.0<=..0.0])
    assert toSeq(s.intervals) == [0.0<=..0.0, 1.0<=..4.0]
  for i in a:
    if not i.isEmpty:
      when type(a) is openArray[Slice]:
        result.intervals.add i.a<=..i.b
      else:
        result.intervals.add i
  sort(result.intervals)
  normalize(result.intervals)

proc toIntervalSet*[V:Ordinal and not range](s: set[V]): IntervalSet[V] =
  ## Construct an interval set from the built-in set type.
  runnableExamples:
    import sequtils
    let s = toIntervalSet({'a'..'z', 'A'..'Z', '0'..'9'})
    assert toSeq(s.intervals) == ['0'..'9', 'A'..'Z', 'a'..'z']
  result.intervals = toSeq(intervals(s))

proc toIntervalSet*[V:range](s: set[V]): IntervalSet[int] =
  ## Construct an interval set from the built-in set type.
  for i in intervals1[V,int](s):
    result.intervals.add i

proc lowerBoundDescending[V, K](a: openArray[V], key: K, cmp: proc(x: V, k: K): int {.closure.}): int =
  result = a.high
  var count = a.high - a.low + 1
  var step, pos: int
  while count != 0:
    step = count shr 1
    pos = result - step
    if cmp(a[pos], key) >= 0:
      result = pos - 1
      count -= step + 1
    else:
      count = step

proc lowerBoundDescending[V](a: openArray[V], key: V): int =
  lowerBoundDescending(a, key, cmp[V])

proc upperBoundDescending[V, K](a: openArray[V], key: K, cmp: proc(x: V, k: K): int {.closure.}): int =
  result = a.high
  var count = a.high - a.low + 1
  var step, pos: int
  while count != 0:
    step = count shr 1
    pos = result - step
    if cmp(a[pos], key) > 0:
      result = pos - 1
      count -= step + 1
    else:
      count = step

proc upperBoundDescending[V](a: openArray[V], key: V): int =
  upperBoundDescending(a, key, cmp[V])

proc firstUpperAfter[V](a: openArray[Interval[V]], key: Boundary[V]): int =
  lowerBound(a, key, proc(x: Interval[V], key: Boundary[V]):int = cmp(x.upper, key))

proc lastLowerBefore[V](a: openArray[Interval[V]], key: Boundary[V]): int =
  upperBoundDescending(a, key, proc(x: Interval[V], key: Boundary[V]):int = cmp(x.lower, key))

proc firstUpperAfter[V](a: openArray[OrdinalInterval[V]], key: V): int =
  lowerBound(a, key, proc(x: Slice[V], key: V):int = cmp(x.b, key))

proc lastLowerBefore[V](a: openArray[OrdinalInterval[V]], key: V): int =
  upperBoundDescending(a, key, proc(x: Slice[V], key: V):int = cmp(x.a, key))

proc overlap[V](s: openArray[SomeInterval[V]], iv: SomeInterval[V]): Slice[int] =
  if len(s) == 0 or iv.isEmpty: 0 .. -1
  else:
    when V is Ordinal:
      let a =
        if iv.a == low(V): iv.a
        else: pred(iv.a)
      let b =
        if iv.b == high(V): iv.b
        else: succ(iv.b)
      firstUpperAfter(s, a) ..  lastLowerBefore(s, b)
    else:
      firstUpperAfter(s, iv.lower) ..  lastLowerBefore(s, iv.upper)

proc contains*[V](s: IntervalSet[V], v: V): bool =
  ## True if `v` lies in one of `s`'s intervals.
  when V is Ordinal:
    let cmp = proc(x: Slice[V], v: V):int =
      if v in x: 0
      elif x.b < v: -1
      else: 1
  else:
    let cmp = proc(x: Interval[V], v: V):int =
      if v in x: 0
      elif x.upper < v: -1
      else: 1
  binarySearch(s.intervals, v, cmp) == 0

proc contains*[V](s: IntervalSet[V], i: SomeInterval[V]): bool =
  ## True if `i` is enclosed by one of `s`'s intervals.
  if i.isEmpty: false
  elif singleton(i): i.a in s
  else:
    let o = overlap(s.intervals, i)
    len(o) == 1 and i in s.intervals[o.a]

proc contains*[V](a,b: IntervalSet[V]): bool =
  # True if `a` contains all intervals of `b`
  if a.isEmpty: return false
  for i in b:
    if i notin a: return false
  true

proc incl[V](a: var seq[SomeInterval[V]], i: SomeInterval[V]) =
  if not i.isEmpty:
    let o = overlap(a, i)
    if len(o) == 0:
      a.insert(i, o.a)
    elif len(o) == 1 and i in a[o.a]: discard
    else:
      a[o.a] = extent(a[o.a], i)
      normalize(a, o)

proc excl[V](a: var seq[SomeInterval[V]], i: SomeInterval[V]) =
  if len(a) == 0 or i.isEmpty: return

  var o = overlap(a, i)
  if len(o) == 0: return
  template start: auto = a[o.a]
  template stop: auto = a[o.b]
  let diff = difference(start, i)
  if not diff[0].isEmpty:
    start = diff[0]
    if not diff[1].isEmpty:
      insert(a, diff[1], o.a+1)
      return
    if o.a == o.b: return
  elif not diff[1].isEmpty:
    start = diff[1]
    if o.a == o.b: return
  else:
    delete(a, o.a)
    if o.a == o.b: return
    dec o.b
  inc o.a
  while o.a < o.b:
    delete(a, o.a)
    dec o.b
  if o.b != len(a):
    if i.upper < stop.upper:
      stop = above(i.upper.v) .. stop.upper
    else:
      delete(a, o.b)

proc incl*[V](s: var IntervalSet[V], i: SomeInterval[V]) =
  ## Includes interval `i` in `s`.
  ##
  ## This doesn't do anything if `i` is already in `s`.
  ##
  ## See also:
  ## * `incl proc <#incl,IntervalSet[V],V>`_ for including a value
  ## * `incl proc <#incl,IntervalSet[V],IntervalSet[V]>`_ for including other set
  ## * `excl proc <#excl,IntervalSet[V],V>`_ for excluding an interval
  runnableExamples:
    var s = IntervalSet[int]()
    incl(s, 0..1)
    incl(s, 1..2)
    assert len(s) == 3
  incl(s.intervals, i)

proc incl*[V](a: var IntervalSet[V], v: V) =
  ## Includes value `v` in `s`.
  ##
  ## This doesn't do anything if `v` is already in `s`.
  ## See also:
  ## * `incl proc <#incl,IntervalSet[V],SomeInterval[V]>`_ for including an interval
  runnableExamples:
    var s = IntervalSet[int]()
    incl(s, 2)
    incl(s, 2)
    assert len(s) == 1
  incl(a, v<=..v)

proc incl*[V](a: var IntervalSet[V], b: IntervalSet[V]) =
  ## Includes all intervals from `b` in `a`.
  ##
  ## This is the in-place version of `a + b<#+,IntervalSet[V],IntervalSet[V]>`_
  ##
  ## See also:
  ## * `excl proc <#excl,IntervalSet[V],IntervalSet[V]>`_ for excluding other set
  ## * `incl proc <#incl,IntervalSet[V],V>`_ for including a value
  ## * `incl proc <#incl,IntervalSet[V],SomeInterval[V]>`_ for including an interval
  runnableExamples:
    var a = toIntervalSet([1..2])
    var b = toIntervalSet([2..4])
    incl(a, b)
    assert len(a) == 4
  for i in b.intervals:
    incl(a.intervals, i)

proc excl*[V](s: var IntervalSet[V], i: SomeInterval[V]) =
  ## Excludes interval `i` from `s`.
  ##
  ## This doesn't do anything if `i` is not found in `s`.
  excl(s.intervals, i)

proc excl*[V](s: var IntervalSet[V], v: V) =
  ## Excludes value `v` from `s`.
  ##
  ## This doesn't do anything if `v` is not found in `s`.
  excl(s, v<=..v)

proc excl*[V](a: var IntervalSet[V], b: IntervalSet[V]) =
  ## Excludes all intervals of `b` from `a`.
  ##
  ## This is the in-place version of `a - b<#-,IntervalSet[V],IntervalSet[V]>`_
  for i in b.intervals:
    excl(a.intervals, i)

func universe*(V: typedesc): auto =
  ## Returns a set containing all values of `V`.
  IntervalSet[V](intervals: @[low(V)<=..high(V)])

func complement*[V](s: IntervalSet[V]): auto =
  ## Returns the complement of `s` with respect to `universe(V)`.
  ##
  ## The same as `not s <#not,IntervalSet[V]>`_.
  result = universe(V)
  excl(result, s)

func union*[V](a, b: IntervalSet[V]): auto =
  ## Returns the union of the sets `a` and `b`.
  ##
  ## The same as `a + b<#+,IntervalSet[V],IntervalSet[V]>`_
  result = a
  incl(result, b)

func difference*[V](a, b: IntervalSet[V]): auto =
  ## Returns the difference of the sets `a` and `b`.
  ##
  ## The same as `a - b<#-,IntervalSet[V],IntervalSet[V]>`_
  result = a
  excl(result, b)

func intersection*[V](a, b: IntervalSet[V]): auto =
  ## Returns the intersection of the sets `a` and `b`.
  ##
  ## The same as `a * b<#*,IntervalSet[V],IntervalSet[V]>`_
  result = a
  excl(result, complement b)

func symmetricDifference*[V](a, b: IntervalSet[V]): auto =
  ## Returns the symmetric difference of the sets `a` and `b`.
  ##
  ## The same as `a -+- b<#-+-,IntervalSet[V],IntervalSet[V]>`_
  result = a
  excl(result, b)
  incl(result, intersection(b,a))

func `not`*[V](s: IntervalSet[V]): auto {.inline.} =
  ## Alias for `complement(s) <#complement,IntervalSet[V]>`_
  complement(s)

func `+`*[V](a, b: IntervalSet[V]): auto {.inline.} =
  ## Alias for `union(a,b) <#union,IntervalSet[V],IntervalSet[V]>`_
  union(a, b)

func `-`*[V](a, b: IntervalSet[V]): auto {.inline.} =
  ## Alias for `difference(a,b) <#difference,IntervalSet[V],IntervalSet[V]>`_
  difference(a, b)

func `*`*[V](a, b: IntervalSet[V]): auto {.inline.} =
  ## Alias for `intersection(a,b) <#intersection,IntervalSet[V],IntervalSet[V]>`_
  intersection(a, b)

func `-+-`*[V](a, b: IntervalSet[V]): auto {.inline.} =
  ## Alias for `symmetricDifference(a,b) <#symmetricDifference,IntervalSet[V],IntervalSet[V]>`_
  symmetricDifference(a, b)
