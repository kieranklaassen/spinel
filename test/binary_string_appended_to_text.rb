# Bytes appended to a text String make it BINARY (ASCII-8BIT), as + does,
# where the bytes hold one past ASCII and the text holds none. << kept the
# receiver UTF-8: a buffer filled from each_char, or from a read, counted
# characters where its bytes are no text, and compared equal to text of the
# same bytes.
data = "caf\xC3\xA9".b                # what File.binread answers

def show(s) = p([s.encoding.to_s, s.size, s.bytes])

buf = +""
data.each_char { |c| buf << c }
show buf
p buf == data, buf == "caf\xC3\xA9"

out = +"hdr:"
out << data
show out
out << data
show out
p out == "hdr:".b + data + data
show((+"") << data)
show((+"q") << data[3] << data[4])
show((+"q").concat(data))
sum = +""
3.times { sum << data }
show sum

# An alias sees the same String.
a = +"x"
b = a
a << data
show b

# ASCII-only bytes leave text as text, and text that holds a character past
# ASCII stays text. Text appended to BINARY bytes is as it was: it gives text
# only where the bytes are ASCII and the text is not.
show((+"q") << "abc".b)
show((+"caf\xC3\xA9") << "abc".b)
show("abc".b << "\xC3\xA9")
show(data.dup << "abc")
show(data.dup << data)

# Text is read as it was.
text = "caf\xC3\xA9"
tb = +""
text.each_char { |c| tb << c }
show tb
show((+"q") << text)
show((+"") << "")
