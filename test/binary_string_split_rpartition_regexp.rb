# split and rpartition by a Regexp cut BINARY (ASCII-8BIT) pieces from a
# BINARY String.
# They were UTF-8 Strings: a piece counted characters where the receiver
# counts bytes.
data = "id=caf\xC3\xA9;x=1\n".b       # what File.binread answers

def show(s) = p([s.encoding.to_s, s.size, s.bytes])

show data.split(/;/)[0]
show data.split(/=/, 2)[1]
show data.split(/(;)/)[1]
show data.rpartition(/=/)[2]

# Text is read as it was.
text = "id=caf\xC3\xA9;x=1\n"
show text.split(/;/)[0]
