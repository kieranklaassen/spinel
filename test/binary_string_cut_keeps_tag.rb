# A String cut from a BINARY (ASCII-8BIT) String is BINARY too. strip, chomp,
# chop, delete_prefix, delete_suffix, squeeze, delete, tr, tr_s, split, lines
# and each_line answered a UTF-8 String: the result counted characters where
# the receiver counts bytes, and compared equal to text of the same bytes.
data = "caf\xC3\xA9  \n".b            # what File.binread answers

def show(s) = p([s.encoding.to_s, s.size, s.bytes])

line = data.strip
show line
p line == "caf\xC3\xA9", line
show data.lstrip
show data.rstrip
show data.chomp
show data.chomp(" \n")
show data.chop
show data.delete_prefix("c")
show data.delete_suffix("\n")
show data.squeeze
show data.squeeze(" ")
show data.squeeze("a-z", " ")
show data.delete("f")
show data.delete("a-f", "^c")
show data.delete("^a-f")
show data.tr("f", "F")
show data.tr("a-f", "A-F")
show data.tr("^a-f", "-")
show data.tr("f", "")
show data.tr_s(" ", "_")
show data.tr_s("^a-f", "-")
show data.split(" ")[0]
show data.split[0]
show data.split("f")[1]
show data.split(" ", 2)[1]
show data.split(nil, 2)[0]
show data.lines[0]
show data.lines(chomp: true)[0]
show data.lines(" ")[0]
show data.each_line.first
show data.each_line(" ").to_a[0]

# A binary String has one-byte characters: chop cuts one byte, split("") cuts
# between bytes, squeeze and delete see two bytes where UTF-8 has one character.
show "caf\xC3\xA9".b.chop
p "caf\xC3\xA9".b.split("").size, "caf\xC3\xA9".b.split("", 5)[4].bytes
show "a\xC3\xC3\xA9".b.squeeze
show "\xE9\xE9a".b.squeeze
show "\xE9a\xE9".b.delete("a")
show "\xE9a\xE9".b.tr("a", "b")
show "\xE9aa\xE9".b.tr_s("a", "b")

# The same through the methods that change the receiver.
d = data.dup
d.strip!
show d
d = data.dup
d.squeeze!
show d
d = data.dup
d.tr!("f", "F")
show d
d = data.dup
d.delete!("f")
show d
d = data.dup
d.chomp!
show d
d = data.dup
d.chop!
show d

# An empty result is BINARY as well, and the empty text String is not.
p ["  ".b.strip.encoding.to_s, "a".b.delete("a").encoding.to_s, "a".b.chop.encoding.to_s,
   "".strip.encoding.to_s, "a".delete("a").encoding.to_s, "a".chop.encoding.to_s]

# tr writes its second argument: text with a character past ASCII, written
# into ASCII-only bytes, gives text, as + does. Nothing written keeps BINARY.
show "abc".b.tr("b", "\xC3\xA9")
show "abc".b.tr("x", "\xC3\xA9")
show "abc".b.tr_s("b", "\xC3\xA9")

# Text is read as it was.
text = "caf\xC3\xA9  \n"
show text.strip
show text.chop.chop.chop.chop
show text.squeeze
show text.delete("\xC3\xA9")
show text.tr("\xC3\xA9", "e")
show text.tr_s(" ", "_")
show text.split(" ")[0]
show text.lines[0]
p text.split("").size, "caf\xC3\xA9".chop
