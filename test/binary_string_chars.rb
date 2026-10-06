# The characters of a BINARY (ASCII-8BIT) String are BINARY Strings of one
# byte. chars answered UTF-8 Strings, so chars.join was a UTF-8 String again:
# it counted characters where the receiver counts bytes, and compared equal
# to text of the same bytes.
data = "caf\xC3\xA9".b                # what File.binread answers

def show(s) = p([s.encoding.to_s, s.size, s.bytes])

show data.chars[3]
show data.chars.last
show data.chars.join
show data.chars.map { |c| c }.join
show data.chars.sort.join
show data.chars.reverse.join
show data.each_char.to_a[4]
p data.chars.size, data.chars.join == data, data.chars.join == "caf\xC3\xA9"

# A boxed receiver's chars are its bytes too.
def pick(n) = n > 0 ? "caf\xC3\xA9".b : 7
show pick(1).chars[3]
show pick(1).chars.join

# An ASCII-only binary String's characters are BINARY as well.
show "ab".b.chars[0]
show "ab".b.chars.join

# Text is read as it was.
text = "caf\xC3\xA9"
show text.chars[3]
show text.chars.join
p text.chars.size, text.chars.join == text
