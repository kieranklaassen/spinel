# An interpolation that is one part alone, "#{s}", answers UTF-8 unless the
# part holds a byte past ASCII in another encoding, as CRuby does. It took
# the part's own encoding, so an ASCII-only binary String came back binary.
b = "a".b
c = "\xff".b
u = "é"
p "#{b}".encoding.to_s, ("#{b}" + "").encoding.to_s
p "#{c}".encoding.to_s, "#{u}".encoding.to_s, "#{1}".encoding.to_s

# through a method, a block and a boxed value
def lone(v) = "#{v}"
p lone(b).encoding.to_s, lone(c).encoding.to_s, lone(u).encoding.to_s
p [b, c].map { |v| "#{v}" }.map { |s| s.encoding.to_s }
x = [b, 1][0]
p "#{x}".encoding.to_s

# the bytes are the part's, and a text String made this way counts characters
s = "#{c}"
p s.bytes, s.size, "#{b}".bytes
t = "#{b}" + "é"
p t.encoding.to_s, t.size

# as before: a literal beside the part
p "x#{b}".encoding.to_s, "#{b}x".encoding.to_s, "x#{c}".encoding.to_s
