# gsub and sub with a Hash read the subject, the match and the replacement
# by their bytes: a NUL byte in any of them is a byte, not its end.
h = { "a" => "1", "b" => "2", "\0" => "N", "c" => "\0\0" }
l = ["a\0b", "\0ab", "ab\0", "c\0c"]
p l.map { |s| s.gsub(/[abc]/, h).bytes }
p l.map { |s| s.gsub(/\0/, h) }
p l.map { |s| s.sub(/b/, h).bytes }
p l.map { |s| s.sub(/\0/, h) }
# a String pattern
p l.map { |s| s.gsub("b", h).bytes }
p l.map { |s| s.gsub("\0", h) }
p l.map { |s| s.sub("b", h).bytes }
p l.map { |s| s.sub("\0b", "\0b" => "!").bytes }
p "a\0b\0b".gsub("\0b", "\0b" => "-")

t = +"a\0b"
t.gsub!(/[ab]/, h)
p t.bytes

# the Hash's default, for a pattern found behind a NUL byte or holding one
z = Hash.new("-")
z["k"] = "v"
p "a\0b".gsub("b", z).bytes
p "a\0b\0".gsub("\0", z)
p "a\0b\0".sub("\0", z)
