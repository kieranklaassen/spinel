# Array#join picked the result's encoding in a second walk over the Array,
# after allocating the result. That allocation can collect, and an Array only
# the call holds went then with its elements: the walk read their lengths and
# their binary marks out of freed memory. Where the result took the slot of
# the piece that holds the high bytes, a join of BINARY (ASCII-8BIT) pieces
# came back UTF-8: 7 of these 200,000 in a plain run, one in eight at
# SPINEL_GC_STRESS=2.
def pair(d, i) = [d.byteslice(7 + i % 2, 8), d.byteslice(0, 8)]

src = ("\xC3\xA9\xC3\xA9\xFF\xC3\xA9" + "z" * 12).b
utf8 = 0
k = 0
while k < 200_000
  r = pair(src, k).join
  utf8 += 1 if r.encoding.to_s != "ASCII-8BIT"
  k += 1
end
p utf8

# with a separator, and with one that only the call holds
bad = 0
k = 0
while k < 400
  r = pair(src, k).join("-")
  bad += 1 if r.encoding.to_s != "ASCII-8BIT" || r.bytesize != 17
  r = pair(src, k).join(k.to_s)
  bad += 1 if r.encoding.to_s != "ASCII-8BIT" || r.bytesize != 16 + k.to_s.size
  k += 1
end
p bad

# text pieces stay text, and a binary piece beside ASCII-only text is binary
def words(i) = ["café", i.to_s, "naïve"]
def mixed(d, i) = ["n=", i.to_s, d.byteslice(3, 2)]
bad = 0
k = 0
while k < 400
  r = words(k).join(" ")
  bad += 1 if r.encoding.to_s != "UTF-8" || r.size != 11 + k.to_s.size
  r = mixed(src, k).join
  bad += 1 if r.encoding.to_s != "ASCII-8BIT" || r.bytesize != 4 + k.to_s.size
  k += 1
end
p bad

r = pair(src, 1).join
p r.encoding.to_s, r.bytes
