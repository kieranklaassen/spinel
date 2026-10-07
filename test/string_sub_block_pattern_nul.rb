# sub and gsub with a String pattern and a block find the pattern by
# bytes: behind a NUL byte of the subject, and whole when it holds one.
l = ["a\0b", "\0ab", "ab\0b", "b\0\0b"]
p l.map { |s| s.sub("b") { "zz" }.bytes }
p l.map { |s| s.gsub("b") { |m| m + m }.bytes }
p l.map { |s| s.sub("\0") { "::" } }
p l.map { |s| s.gsub("\0") { "::" } }
p l.map { |s| s.sub("\0b") { "!" }.bytes }
p l.map { |s| s.gsub("b\0") { "!" }.bytes }

t = +"a\0b\0b"
t.gsub!("b") { "q" }
p t.bytes
u = +"a\0b\0b"
p u.sub!("\0b") { "-" }
# a pattern read at run time
pat = l[0][1, 2]
p "xa\0bx\0b".gsub(pat) { |m| m.bytesize.to_s }
# as before
p "a-b-c".gsub("-") { "+" }, "abc".sub("x") { "y" }, "ab".gsub("") { "." }
# a pattern longer than what is left of the subject
p "a=qqb".gsub("=\0x") { "-" }, "".sub("\0") { "" }.bytes, "ab".sub("b\0\0\0\0\0\0\0\0") { "q" }
v = +"a"
p v.sub!("a\0") { "q" }, v
y = "ab"
p y.sub("b\0c") { "Z" }
