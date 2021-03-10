include intervalsets/private/boundaries

when isMainModule:
  doAssert adjacient('a', 'b')
  doAssert adjacient(1, 2)
  doAssert not adjacient(0, 2)
  doAssert not adjacient(1.0, 2.0)
  doAssert below(1) < above(1)
  doAssert above(1) == below(2)
  doAssert above(1.0) != below(2.0)
  doAssert below(0) < 0
  doAssert 0 < above(0)
