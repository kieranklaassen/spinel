# scrub with a block cut each valid run and each invalid sequence through a
# pointer into the receiver. Such a pointer has no header of its own, and the
# runtime read one behind it: after an invalid byte that a heap String's
# marker uses (0xFE, 0xFC, 0xFD, 0xF1, 0xFB, 0xFA, 0xF8) the piece took its
# encoding from the receiver's own bytes, and the collector, which had been
# handed the pointer as a root, marked a String that is none.

# The second invalid byte follows 0xFE, and the receiver's bytes seventeen to
# fourteen before it end on 0xA9: the block's parameter was a binary String.
s = ("\xC3\xA9" * 10) + "\xFE\xFDz"
p s.scrub { |b| b.encoding.to_s[0, 3] }
seen = []
r = s.scrub { |b| seen << [b.bytes, b.encoding.to_s, b.valid_encoding?]; "?" }
p seen
p r, r.encoding.to_s, r.valid_encoding?

# the same after each byte a marker uses, then after two that none does
["\xFC\xFC", "\xFD\xFD", "\xF1\xF1", "\xFB\xFB", "\xFA\xFA", "\xF8\xF8", "\xFF\xFF", "\xC0\xC0"].each do |pair|
  t = ("\xC3\xA9" * 10) + pair + "z"
  p t.scrub { |b| b.encoding.to_s[0, 3] }
end

# The collector runs inside the call: the pointer after 0xFE or 0xFD was a
# root, and marking it faulted.
bad = "ab\xFEcd=\xFDef" * 300
n = 0
400.times do |i|
  r = (bad + i.to_s).scrub { |b| "?" }
  n += r.bytesize
end
p n

# the parameter kept past the call, and the receiver after it
keep = []
t = "ab\xFEcd\xFD\xFCef"
r = t.scrub { |b| keep << b; "-" }
p keep.map { |b| [b.bytes, b.encoding.to_s, b.size] }
p r, t.bytes

# as before
p "a\xE3\x81b".scrub { |b| "<" + b.bytesize.to_s + ">" }
p "a\xC3\xA9b".scrub { "?" }, "".scrub { "?" }
