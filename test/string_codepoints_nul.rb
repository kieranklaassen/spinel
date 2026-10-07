# codepoints without a block walks the String to its byte length, as it
# does with one: a NUL is a character like any other
s = "a\0b"
p s.codepoints
p s.codepoints.pack("U*") == s
p "é\0日".codepoints
p "\0".codepoints
t = +"a\0"
t << "b"
p t.codepoints.length
# each_codepoint without a block answers the same members
p s.each_codepoint.to_a
p s.each_codepoint.first(2)
# a binary String's codepoints are its bytes
p "é".b.codepoints
p "\xff\0\x7f".b.codepoints
# a receiver known only at run time
x = ARGV.size > 5 ? 1 : s
p x.codepoints
