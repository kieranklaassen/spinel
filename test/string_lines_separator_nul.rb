# lines and each_line with a separator read the String by bytes: a NUL
# byte is a byte of a line, and a separator may be one or hold one.
l = ["a\0b", "\0ab", "ab\0", "a\0b\0\0c"]
p l.map { |s| s.lines("\0").map(&:bytes) }
p l.map { |s| s.lines("b").map(&:bytes) }
p l.map { |s| s.lines("\0", chomp: true) }
p l.map { |s| s.each_line("\0").to_a.length }
p "x\0y\n\nz\0".lines("").map(&:bytes)
p "a\0-b\0-c".lines("\0-")
n = 0
"a\0b,c\0".each_line(",") { |x| n += x.bytesize }
p n
# as before
p "a,b,c".lines(","), "".lines(","), "a\n\nb".lines("")
