# join with a separator longer than its buffer wrote past the buffer: the
# String, Integer and Float Array joins grew a 256-byte buffer by doubling it
# once for a separator, however long the separator was.

def strs(i) = ["a" + i.to_s, "b"]
def ints(i) = [i, i + 1, i + 2]
def flts(i) = [i + 0.5, 2.25]

def show(r, ch)
  p [r.bytesize, r.count(ch), r[0, 4], r[-3, 3]]
end

# a separator of 1,000 bytes after a short first element
sep = "x" * 1000
show(strs(1).join(sep), "x")
show(ints(7).join(sep), "x")
show(flts(1).join(sep), "x")

# three and more separators, each past the doubled buffer
big = "y" * 5000
show(["a2", "b", "c", "d"].join(big), "y")
show([1, 22, 333, 4444].join(big), "y")
show([1.5, 2.5, 3.5].join(big), "y")

# around the buffer's own size, and one doubling past it
[255, 256, 257, 511, 512, 513, 1023, 1025].each do |n|
  s = "-" * n
  p [n, strs(n).join(s).count("-"), ints(n).join(s).count("-"), flts(n).join(s).count("-")]
end

# a long element before a long separator, and a separator that is not ASCII
long = "e" * 600
r = [long, "t"].join("z" * 700)
p [r.bytesize, r.count("e"), r.count("z"), r[-2, 2]]
wide = "é" * 400
r = ["p", "q", "r"].join(wide)
p [r.bytesize, r.size, r.encoding.to_s, r.valid_encoding?, r[0, 2], r[-2, 2]]

# many joins in a row keep their bytes
n = 0
300.times do |i|
  r = strs(i).join(sep)
  n += 1 if r.bytesize == 2 + i.to_s.size + 1000 && r.end_with?("xb") && r.count("x") == 1000
end
p n
