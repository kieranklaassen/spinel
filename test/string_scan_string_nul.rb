# scan with a String pattern finds it by bytes: the search goes on behind
# a NUL byte of the subject, and a pattern that holds one is matched whole.
l = ["a\0b", "\0ab", "ab\0b", "b\0\0b\0"]
p l.map { |s| s.scan("b").length }
p l.map { |s| s.scan("\0").length }
p l.map { |s| s.scan("\0b").map(&:bytes) }
p "x,a\0b,a\0b".scan("a\0b")[1].bytesize
p "é\0日".scan("").length
p "a\0bb\0b".scan("b\0").map(&:bytes)

# with a block, and the match its block reads
n = 0
"b\0b\0b".scan("b") { |m| n += m.bytesize }
p n
at = []
"q\0xb\0xb".scan("xb") { at << $~.begin(0) }
p at
"a\0b".scan("b")
p $~ && $~.pre_match.bytes
