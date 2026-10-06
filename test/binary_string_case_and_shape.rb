# A BINARY (ASCII-8BIT) String has one-byte characters and no letter past
# ASCII. upcase, downcase, swapcase and capitalize read its bytes as UTF-8 and
# rewrote the second byte of a sequence (C3 A9 became C3 89); reverse turned
# characters, not bytes; succ carried into a character; center, ljust and
# rjust padded to a width in characters. All of them answered a UTF-8 String.
data = "caf\xC3\xA9 Bar".b            # what File.binread answers

def show(s) = p([s.encoding.to_s, s.size, s.bytes])

show data.upcase
show data.downcase
show data.swapcase
show data.capitalize
show data[3, 6].capitalize
show data.reverse
p data.reverse.reverse == data
show data.center(13)
show data.center(13, ".")
show data.center(14, "ab")
show data.ljust(12)
show data.ljust(12, ".")
show data.rjust(12)
show data.rjust(13, "ab")
show data.ljust(3)
show data.succ
show data[0, 5].succ
show "az".b.succ
show "a\xC3\xA9".b.succ
show "Zz".b.succ
show "\xFF".b.succ
show "\xFE\xFF\xFF".b.succ
show "-\xFF".b.succ
show "\xE9\xFFz".b.upcase
show "\xC3\xBF".b.upcase
show "\xC5\xBF".b.downcase

# The same through the methods that change the receiver.
d = data.dup
d.upcase!
show d
d = data.dup
d.downcase!
show d
d = data.dup
d.swapcase!
show d
d = data.dup
d.capitalize!
show d
d = data.dup
d.reverse!
show d
d = data.dup
d.succ!
show d

# An empty result is BINARY as well, and the empty text String is not.
p ["".b.upcase.encoding.to_s, "".b.reverse.encoding.to_s, "".b.succ.encoding.to_s, "".b.center(0).encoding.to_s,
   "".upcase.encoding.to_s, "".reverse.encoding.to_s, "".succ.encoding.to_s, "".center(0).encoding.to_s]

# The pad is written: text with a character past ASCII, padded onto
# ASCII-only bytes, gives text, as + does. No pad written keeps BINARY.
show "abc".b.ljust(5, "\xC3\xA9")
show "abc".b.ljust(3, "\xC3\xA9")
show "abc".b.center(5, "\xC3\xA9")
show "abc".b.rjust(4, "\xC3\xA9")

# Text is read as it was.
text = "caf\xC3\xA9 Bar"
show text.upcase
show text.swapcase
show text.capitalize
show text.reverse
show text.center(13, ".")
show text.ljust(12)
show text.succ
show "a\xC3\xA9".succ
