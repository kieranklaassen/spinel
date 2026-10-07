# chomp and chomp! cut a separator that begins with a NUL byte: it is a
# separator like any other, not the empty one that strips newlines.
l = ["PATH=/bin\0", "a\0b\0", "\0", "a\n"]
p l.map { |s| s.chomp("\0").bytes }
p "a\0b\0".chomp("\0b\0").bytes
p "a\0\n".chomp("\0\n").bytes

t = +"PATH=/bin\0"
p t.chomp!("\0"), t.bytes
u = +"a\n"
p u.chomp!("\0"), u.bytes

# a separator read at run time, and the String handed on
z = l[2]
p "PATH=/bin\0".chomp(z).split("=")
