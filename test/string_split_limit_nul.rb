# split with a positive limit measures the String and the separator by
# their byte lengths, as the unlimited split does: a NUL ends neither
p "x,a\0b".split(",", 2)
p "x,a\0b".split(",", 2)[1].bytesize
p "a\0b,c,d".split(",", 2)
p "a\0b".split(",", 1)[0].bytesize
p "xQQa\0bQQc".split("QQ", 2).map(&:bytesize)
p "a\0bQQc\0dQQe".split("QQ", 3).map(&:bytesize)
# a NUL in the separator, and a separator that is one
p "a,\0b,\0c".split(",\0", 2)
p "a\0b\0c".split("\0", 2)
p "a\0b\0c".split("\0", 5)
# no separator: one character a field, the rest in the last
p "a\0bc".split("", 3)
p "a\0".split("", 5)
t = +"x,a"
t << "\0b,c"
n = 3
p t.split(",", n).map(&:bytesize)

# a field whose trailing NUL chomp cut off ends there
p "PATH=/bin\0".chomp("\0").split("=", 2)
