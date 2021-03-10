import intervalsets
import sequtils

template expectIntervals(s, i) =
  doAssert toSeq(s.intervals) == i

var s4 = IntervalSet[int]()
incl(s4, 0)
expectIntervals s4, [0..0]
incl(s4, 1)
expectIntervals s4, [0..1]
incl(s4, 4..5)
expectIntervals s4, [0..1, 4..5]
incl(s4, 2..3)
expectIntervals s4, [0..5]
excl(s4, 1)
expectIntervals s4, [0..0, 2..5]
excl(s4, 0..2)
expectIntervals s4, [3..5]
excl(s4, 4)
expectIntervals s4, [3..3, 5..5]
excl(s4, 5)
expectIntervals s4, [3..3]
excl(s4, 3)
expectIntervals s4, []

var s5 = IntervalSet[char]()
incl(s5, 'a')
expectIntervals s5, ['a'..'a']
incl(s5, 'b')
expectIntervals s5, ['a'..'b']
incl(s5, 'c'..'d')
expectIntervals s5, ['a'..'d']
let s6 = s5 * toIntervalSet(['b', 'd'])
expectIntervals s6, ['b'..'b', 'd'..'d']

var s7 = toIntervalSet([0.0<=..1.0])
excl(s7, 0.5)
expectIntervals s7, [0.0<=..<0.5, 0.5<..1.0]
incl(s7, 0.5)
expectIntervals s7, [0.0<=..1.0]
