import intervalsets
import sequtils

let s0 = toIntervalSet([1..10])
doAssert len(s0) == 10
doAssert toSeq(s0) == toSeq(1..10)

let s1 = toIntervalSet([1..2, 5..8, 8..40])
doAssert toSeq(s1.intervals) == [1..2, 5..40]

let s2 = toIntervalSet([0.0<..<1.0])
doAssert toSeq(s2.intervals) == [0.0<..<1.0]

let s3 = toIntervalSet([0.0..1.0, 3.0..3.0, 0.5..2.0])
doAssert toSeq(s3.intervals) == [0.0<=..2.0, 3.0<=..3.0]

let s4 = toIntervalSet({0..10, 12, 13, 14})
doAssert toSeq(s4.intervals) == [0..10, 12..14]

let s5 = toIntervalSet({'a'..'z', 'A'..'Z'})
doAssert toSeq(s5.intervals) == ['A'..'Z', 'a'..'z']
