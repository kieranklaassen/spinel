# sub and gsub with a block keep what follows the last match to the
# subject's byte length: a NUL byte behind it is not the subject's end.
l = ["a\0b", "\0ab", "ab\0", "é\0日b"]
p l.map { |s| s.gsub(/a/) { "q" }.bytes }
p l.map { |s| s.gsub(/x/) { "q" }.bytesize }
p l.map { |s| s.sub(/b/) { "zz" }.bytes }
p l.map { |s| s.sub(/\0/) { "::" } }
p l.map { |s| s.gsub(/[ab]/) { |c| c.upcase }.bytes }
# a String pattern that is not found
p "a\0b".sub("x") { "y" }.bytes
p "a\0b".gsub("x") { "y" }.bytes

t = +"a\0b\0"
t.gsub!(/a/) { "q" }
p t.bytes
u = +"ab\0"
u.sub!(/b/) { "q" }
p u.bytes
