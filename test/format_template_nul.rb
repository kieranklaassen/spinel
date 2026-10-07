# format, sprintf and String#% read their template to its byte length: a
# NUL byte in it is copied like any other byte, and what follows it is
# still formatted.
p format("a\0b%s", "c").bytes
p format("%s\0%s", "x", "y").bytes
p format("\0%d|%-3s|", 5, "z").bytes
p format("x\0y").bytes
p sprintf("%s\0", "a\0b").bytes
p ("x\0%s" % "c").bytes
p ("%d\0%d" % [1, 2]).bytes
p ("a\0b" % []).bytesize
t = "%s\0%%\0%05.1f"
s = format(t, "q", 2.5)
p s.bytes, s.bytesize
# too few arguments past the NUL is still an error
begin
  format("a\0%s%s", "b")
rescue ArgumentError => e
  puts e.message
end
