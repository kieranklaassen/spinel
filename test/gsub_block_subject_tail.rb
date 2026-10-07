# sub and gsub with a block copied what stands between and after the matches
# through a pointer into the subject. Such a pointer has no header of its own,
# and the runtime read one: where a match ends on a byte a heap String's
# marker uses (0xFE, 0xFC, 0xFD, 0xF1, 0xFB, 0xFA, 0xF8), the length of what
# follows came from the subject's own bytes, thirteen to ten before it.
#
# Here those four bytes spell 40, and 40 bytes were copied from a tail of 2:
# the answer was 53 bytes, 38 of them whatever the heap held past the subject.
v = ([40, 0, 0, 0] + [65] * 8 + [0xFE] + [99, 100]).pack("C*")
r = v.sub(/\xFE/n) { "-" }
p v.bytesize, r.bytesize
p r.bytes
# Ordinary text there spells hundreds of megabytes ("4567" is 926,299,444).
o = "0123456789abcdef\xFEtail".b
p o.gsub("\xFE".b) { "-" }.bytesize
# Here they spell 1, and one byte of the tail was copied.
v = ([1, 0, 0, 0] + [65] * 8 + [0xFE] + [99, 100]).pack("C*")
r = v.gsub(/\xFE/n) { "-" }
p r.bytesize, r.bytes

# A shorter subject has no such bytes of its own: the tail was dropped.
s = "ab\xFEcd=ef".b
p s.sub("\xFE".b) { "-" }.bytes
p s.gsub("\xFE".b) { "-" }.bytes
p s.sub(/\xFE/n) { "-" }.bytes
p s.gsub(/\xFE/n) { |m| m.bytesize.to_s }.bytes
p s.sub(/b\xFE/n) { |m| m.bytesize.to_s }.bytes

# every byte a marker uses, then two that none does
[0xFE, 0xFC, 0xFD, 0xF1, 0xFB, 0xFA, 0xF8, 0xF0, 0x41].each do |b|
  t = [97, 98, b, 99, 100, 61, b, 101, 102].pack("C*")
  m = [b].pack("C")
  p [b, t.sub(m) { "-" }.bytes, t.gsub(m) { |x| x.bytesize.to_s }.bytes]
end

# the block's parameter is a binary String at every match
t = "ab\xFEcd=\xFEef".b
seen = []
r = t.gsub("\xFE".b) { |x| seen << [x.bytes, x.encoding.to_s]; "-" }
p seen, r.bytes

# the bang forms
u = "ab\xFEcd=\xFEef".b
p u.sub!("\xFE".b) { "+" }.nil?, u.bytes
p u.gsub!(/\xFE/n) { "+" }.nil?, u.bytes

# a block that itself substitutes
w = "a\xFEb c\xFEd".b
p w.gsub(/[^ ]+/n) { |x| x.sub("\xFE".b) { "+" } }.bytes

# a receiver read from an Array of mixed values
a = ["ab\xFEcd=ef".b, 1]
p a[0].sub("\xFE".b) { "-" }.bytes

# a text subject that holds a NUL: what follows the last match was cut at it
n = "a\0bXc\0dXe\0f"
p n.gsub(/X/) { "-" }, n.sub(/X/) { "-" }
# a NUL before, between and behind the matches, and no match at all
nl = ["a\0b", "\0ab", "ab\0", "é\0日b"]
p nl.map { |q| q.gsub(/a/) { "q" }.bytes }
p nl.map { |q| q.gsub(/x/) { "q" }.bytesize }
p nl.map { |q| q.sub(/b/) { "zz" }.bytes }
p nl.map { |q| q.sub(/\0/) { "::" } }
p nl.map { |q| q.gsub(/[ab]/) { |c| c.upcase }.bytes }
p "a\0b".sub("x") { "y" }.bytes, "a\0b".gsub("x") { "y" }.bytes
nt = +"a\0b\0"
nt.gsub!(/a/) { "q" }
nu = +"ab\0"
nu.sub!(/b/) { "q" }
p nt.bytes, nu.bytes

# many matches, a long subject
l = ("ab\xFE" * 400).b
r = l.gsub("\xFE".b) { "-" }
p r.bytesize, r.count("-")

# text: as before
x = "a\xC3\xA9X\xE6\x97\xA5=\xC3\xA9Xb"
p x.sub("X") { |m| m + m }, x.gsub(/X/) { |m| m.bytesize.to_s }
p x.gsub(/\xC3\xA9/) { |m| m.size.to_s }, x.gsub("X") { "" }.size
p "aXbXc".gsub("X") { 2 }, "aXbXc".sub(/X/) { nil }

# A String pattern's match is the pattern: the block's parameter has the
# pattern's encoding at every match, a Regexp's match has the subject's.
bs = "ab\xFE=cd=ef".b
ts = "ab=cd=ef"
e = []
bs.gsub("=") { |m| e << m.encoding.to_s; "-" }
bs.sub("=") { |m| e << m.encoding.to_s; "-" }
ts.gsub("=".b) { |m| e << m.encoding.to_s; "-" }
bs.gsub("=".b) { |m| e << m.encoding.to_s; "-" }
bs.gsub(/=/) { |m| e << m.encoding.to_s; "-" }
ts.gsub(/=/) { |m| e << m.encoding.to_s; "-" }
p e
k = 0
r = bs.gsub("=") { |m| k += 1; k == 2 ? m.encoding.to_s : "-" }
p r.bytesize, r.bytes.last(8)
# a pattern that is a String or a Regexp only at run time
e = []
["=", /=/, "=".b].each { |pt| bs.gsub(pt) { |m| e << m.encoding.to_s; "-" } }
p e
