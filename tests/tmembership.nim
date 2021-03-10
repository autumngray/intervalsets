import intervalsets

let s1 = toIntervalSet([1..2, 5..8, 8..40])
doAssert 1..2 in s1
doAssert 2..4 notin s1
doAssert 3..4 notin s1
doAssert 3..5 notin s1
doAssert 1 in s1
doAssert 3 notin s1

let s2 = toIntervalSet([0.0<..<1.0])
doAssert 0.0 notin s2
doAssert 1.0 notin s2
doAssert 0.1 in s2
doAssert 0.0<..<1.0 in s2

let s3 = toIntervalSet([0.0..1.0, 3.0..3.0, 0.5..2.0])
doAssert 0.0 in s3
doAssert 2.1 notin s3
