import strutils

const
  bitSize = 256
  byteSize = bitSize div 8
type
  Base256 = array[byteSize, uint8]
  Int256* = distinct Base256

# not exposed
proc `[]`(v: Int256, i: int): uint8 = Base256(v)[i]
# not exposed
proc `[]=`(v: var Int256, i: int, val: uint8) =
  Base256(v)[i] = val
# not exposed
proc len(v: Int256): int = Base256(v).len
# not exposed
iterator pairs(v: Int256): (int, uint8) =
  for i in 0..< v.len:
    yield (i, v[i])

proc toNum(c: char): uint8 =
  assert c in {'0'..'9'} or c in {'A'..'F'} or c in {'a'..'f'}
  var base = 0
  case c
  of {'0'..'9'}: base = ord('0')
  of {'A'..'F'}: base = ord('A') - 10
  of {'a'..'f'}: base = ord('a') - 10
  else:
    raiseAssert "ERROR non-hex input to Int256"
  result = uint8(c.ord - base)

proc i256*(v: string): Int256 =
  ## Hex
  assert v.len mod 2 == 0
  let startByte = v.len div 2
  for i in 0..< startByte:
    let
      p = i * 2
      c1 = v[p].toNum
      c2 = v[p + 1].toNum
      byteVal = c1 shl 4 or c2
    result[startByte - i - 1] = byteVal

proc i256*(v: int): Int256 =
  cast[ptr int](unsafeAddr(result))[] = v

proc `$`*(v: Int256): string =
  result = newString(byteSize * 2 + 2)
  result[0..1] = "0x"
  for i in countDown(byteSize - 1, 0):
    let p = i * 2 + 2
    result[p..p + 1] = v[byteSize - i - 1].toHex

proc `not`*(v: Int256): Int256 =
  for i, b in v:
    result[i] = 255'u8 - b

proc `+`*(v1, v2: Int256): Int256 =
  var
    intermediate: int
    carry = 0
  for i in 0..< byteSize:
    intermediate = int(v1[i]) + int(v2[i]) + carry
    carry = 0
    if intermediate > 255:
      result[i] = uint8(intermediate and 0xff)
      carry = intermediate shr 8
    else:
      result[i] = uint8(intermediate)
  #assert carry == 0  # can't use this assert when subtracting!

proc `-`*(v: Int256): Int256 =
  result = v.not + i256(1)

proc `-`*(v1, v2: Int256): Int256 =
  var negV2 = -v2
  result = v1 + negV2

proc `==`*(v1, v2: Int256): bool =
  for i in 0..<byteSize:
    if v1[i] != v2[i]: return false
  return true

proc isPositive*(v: Int256): bool = (v[byteSize - 1] and 0xff).int > 0 

proc `>`*(v1, v2: Int256): bool =
  let x = v2 - v1
  return x.isPositive

proc `<`*(v1, v2: Int256): bool =
  let x = v1 - v2
  return x.isPositive

