# ARGF.read answers every byte of its input: a NUL byte inside a line is
# kept, with what follows it on that line.
s = ARGF.read
p s.bytesize, s.count("\0"), s.lines.length
p s.bytes
