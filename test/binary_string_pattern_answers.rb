# What a pattern answers for a BINARY (ASCII-8BIT) String is BINARY too: the
# result of sub and gsub, the pieces scan and partition cut, a slice by
# a Regexp, and the Strings a match holds ($~, $1, pre_match, post_match).
# They were UTF-8 Strings: the result counted characters where the receiver
# counts bytes, and compared equal to text of the same bytes.
data = "id=caf\xC3\xA9;x=1\n".b       # what File.binread answers

def show(s) = p([s.encoding.to_s, s.size, s.bytes])

show data.sub("=", ":")
show data.sub("q", ":")
show data.gsub("=", ":")
show data.gsub("q", ":")
show data.sub(/=/, ":")
show data.gsub(/=/, ":")
show data.gsub(/q/, ":")
show data.sub(/(\w+)=(\w+)/, "\\2=\\1")
show data.gsub("", "-")
show data.scan(/=\w+/)[0]
show data.scan("=")[1]
show data.scan(/(\w)=(.)/)[0][1]
p data.scan(/./).size, data.scan("").size
show data[/caf../]
show data[/=(.....)/, 1]
show data.slice(/x=\d/)
m = data.match(/=(\w+)(.)/)
show m[0]
show m[1]
show m[2]
show m.pre_match
show m.post_match
show m.to_a[1]
show m.captures[0]
show data.match(/(?<key>\w+)=/)[:key]
if data =~ /f(..);/
  show $~[0]
  show $1
  show $`
  show $'
end
show data.partition(/;/)[0]
show data.partition(/;/)[1]

# The same through the methods that change the receiver.
d = data.dup
d.sub!("=", ":")
show d
d = data.dup
d.gsub!(/=/, ":")
show d
d = data.dup
show d.slice!(/caf../)

# An empty result is BINARY as well, and the empty text String is not.
e = "a".b
p [e.sub("a", "").encoding.to_s, e.gsub(/a/, "").encoding.to_s, e[/b*/].encoding.to_s,
   e.match(/a/).pre_match.encoding.to_s, e.match(/a/).post_match.encoding.to_s,
   "a".sub("a", "").encoding.to_s, "a"[/b*/].encoding.to_s, "a".match(/a/).pre_match.encoding.to_s]

# The replacement is written: text with a character past ASCII, written into
# ASCII-only bytes, gives text, as + does. No match keeps BINARY.
show "abc".b.sub("b", "\xC3\xA9")
show "abc".b.sub("x", "\xC3\xA9")
show "abc".b.gsub("b", "\xC3\xA9")
show "abc".b.sub(/b/, "\xC3\xA9")
show "abc".b.gsub(/b/, "\xC3\xA9")
show "abc".b.gsub(/x/, "\xC3\xA9")

# Text is read as it was.
text = "id=caf\xC3\xA9;x=1\n"
show text.sub("=", ":")
show text.gsub(/=/, ":")
show text.scan(/=\w+/)[0]
show text[/caf./]
show text.match(/=(\w+)/)[1]
p text.scan(/./).size, text.gsub("", "-").size
