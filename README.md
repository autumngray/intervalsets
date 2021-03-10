# intervalsets
Implementation of a set of disjoint intervals.

## Usage
```nim
var s = toIntervalSet({'A'..'Z', 'a'..'z'})
echo s # {'A'..'Z', 'a'..'z'}
excl(s, 'e'..'f')
echo s # {'A'..'Z', 'a'..'d', 'g'..'z'}
incl(s, 'e')
echo s # {'A'..'Z', 'a'..'e', 'g'..'z'}

echo toIntervalSet([0..0, 2..4, 5..6]) # {0, 2..6}
```
