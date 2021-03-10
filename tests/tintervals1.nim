import intervalsets/intervals

when isMainModule:
  let i1 = 1.0<..<2.0
  doAssert open(i1)
  doAssert i1 == above(1.0)..below(2.0)

  let i2 = 1..2
  doAssert closed(i2)

  let i3 = 2..3
  doAssert i2 < i3
  doAssert overlap(i2, i3)
  doAssert intersection(i2, i3) == 2..2
  doAssert extent(i2, i3) == 1..3

  let i4 = 4<=..5
  doAssert i4 == 4..5
  doAssert closed(i4)

  let i5 = 4<=..<5
  doAssert i5 == 4..4
  doAssert i5 < i4

  doAssert isEmpty(2.0<=..1.0)
  doAssert not overlap(0.0<=..<1.0, 1.0<..2.0)

  doAssert singleton(1..1)
  doAssert not singleton(1..2)

  doAssert difference(0..4, 1..2) == [0..0, 3..4]
