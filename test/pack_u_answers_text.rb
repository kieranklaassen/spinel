# Array#pack answers UTF-8 text where its template holds a U and no directive
# but U, m, M and u; with any other directive it answers bytes (ASCII-8BIT).
# It answered bytes for every template, so codes.pack("U*") was not the
# String it spells: == was false and size counted bytes.

word = "caf\xC3\xA9"
s = word.codepoints.pack("U*")
puts s.encoding
p s == word
p s.size, s.bytesize, s.chars.size
p s[-1] == "\xC3\xA9"
p s.inspect == word.inspect
p s.ljust(6, ".").size
p s.reverse.bytes
p s.valid_encoding?

# beside text
t = "\xC3\xA9:" + s
puts t.encoding
p t.size
u = +"\xC3\xA9:"
u << s
p u.size, u == "\xC3\xA9:caf\xC3\xA9"
p word.include?([0xe9].pack("U")), word.index([0xe9].pack("U"))

# as a key and in a case
h = { "\xC3\x89" => 1 }
p h[[0xc9].pack("U")]
case [0xe9].pack("U")
when "\xC3\xA9" then puts "hit"
else puts "miss"
end

# the template: counts and blanks beside U
puts [0xe9, 0x41].pack("U2").encoding
puts [0xe9, 0x41].pack("U U").encoding
puts [0xe9, 0x41].pack("UU").encoding
p [0xe9, 0x41].pack("U U").size
puts [0x41, 0x42].pack("U*").encoding
puts [0x41].pack("U").encoding
puts [].pack("U*").encoding
p [0x3042, 0x3044].pack("U*").size
p [0x1f600].pack("U").size
p [0x3042, 0x3044].pack("U*") == "\xE3\x81\x82\xE3\x81\x84"

# every kind of Array
ints = [99, 97, 102, 233]
p ints.pack("U*") == word
mixed = [233, "x", 1.5]
p mixed.first(1).pack("U") == "\xC3\xA9"
p word.unpack("U*").pack("U*") == word
p word.codepoints.map { |c| c }.pack("U*").size
cs = []
word.each_char { |c| cs << c.ord }
p cs.pack("U*") == word

# U beside m, M and u is text; they are ASCII
m = [233, "ab"].pack("Um")
puts m.encoding
p m.size, m.bytesize
puts [233, "ab"].pack("UM").encoding
puts [233, "ab"].pack("Uu").encoding
puts ["ab", 233].pack("mU").encoding

# any other directive: bytes, as before
puts [0xe9, 1].pack("UC").encoding
puts [1, 0xe9].pack("CU").encoding
p [0xe9, 1].pack("UC").size
puts [0xe9].pack("Ux").encoding
puts [0x63, 0x61].pack("C*").encoding
puts ["ab"].pack("a2").encoding
puts [0xe9].pack("w").encoding
puts [1].pack("N").encoding
puts [0xe9, 1].pack("U n").encoding
p [0xc3, 0xa9].pack("C*") == "\xC3\xA9", [0xc3, 0xa9].pack("C*").size
