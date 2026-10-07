# Array#sum with a String seed joins whole Strings: a NUL byte in the seed
# or in a member is a byte, not that String's end.
a = ["a\0b", "c", "\0d", "e\0"]
p a.sum("").bytes
p a.sum("x\0y").bytes
p ["a\0b"].sum("").bytesize
p "a\0b\0".chars.sum("").bytes
s = a.sum("")
p s.bytesize, s.count("\0"), s == a.join
