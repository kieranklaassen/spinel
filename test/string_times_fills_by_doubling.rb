# String#* fills its answer by doubling what is already filled, so every
# count and every unit length has to come out as the unit written count
# times: counts around each power of two, where the last copy is a partial
# one, a unit of one byte, a multibyte unit, a unit holding a NUL, a binary
# unit, and a count large enough that the copies are no longer small.
def built(unit, n)
  s = +""
  n.times { s << unit }
  s
end

bad = 0
["x", "ab", "pad", "hello", "0123456", "é", "日本", "a\0b"].each do |unit|
  0.upto(70) do |n|
    bad += 1 unless unit * n == built(unit, n)
  end
  [127, 128, 129, 255, 256, 257, 1000, 1023, 1024, 1025].each do |n|
    r = unit * n
    bad += 1 unless r == built(unit, n)
    bad += 1 unless r.bytesize == unit.bytesize * n && r.size == unit.size * n
  end
end
p bad

s = "pad" * 150_000
p s.bytesize, s[0, 7], s[-7, 7], s[224_999, 5], s.count("p"), s.count("a"), s.count("d")
t = "x" * 450_001
p t.bytesize, t.count("x"), t[450_000]
u = "ab\0" * 100_001
p u.bytesize, u.count("\0"), u[-4, 4].bytes
b = "\xff\x00".b * 65_537
p b.encoding == Encoding::BINARY, b.bytesize, b.getbyte(0), b.getbyte(131_072), b.getbyte(131_073)
m = "é" * 33_333
p m.size, m.bytesize, m[33_332] == "é", m.valid_encoding?
p ("ab" * 1), ("ab" * 2), ("ab" * 3), ("" * 5), ("q" * 0)
