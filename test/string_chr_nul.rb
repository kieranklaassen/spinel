# String#chr of a String that begins with a NUL byte is that byte, not "".
l = ["\0ab", "\0", "\0\0", "\0é"]
p l.map { |s| s.chr.bytes }
p l.map { |s| s.chr.empty? }
p "\0ab".chr == "\0", "\0ab".chr.bytesize
# as before
p "".chr, "a\0b".chr, "é\0".chr
