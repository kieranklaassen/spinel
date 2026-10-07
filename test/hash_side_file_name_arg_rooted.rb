# each_key.to_a and each_value.to_a root the Hash they read, and
# File.extname and File.basename with a suffix the String they read: each
# allocated its answer first, and a fresh receiver or argument, held by
# nothing else, could be freed there. SPINEL_GC_STRESS=2 shows it: the
# Arrays came back [] and [nil, nil], the name as bytes of 0xdb.

def hs(x) = "h" + x
def yih(i) = {a: i, b: 2}
def sph(i) = {hs("a") => i, hs("b") => hs("lit")}
def pph(i) = {i => hs("a"), hs("k") => 2, s: nil}

p yih(1).each_key.to_a, yih(1).each_value.to_a
p sph(1).each_key.to_a, sph(1).each_value.to_a
p pph(1).each_key.to_a, pph(1).each_value.to_a

s = hs("ello world")
t = hs("xyz")
p File.basename(s + t + ".rb", ".rb") + File.extname(s + ".txt")
p File.basename(s + "/" + t + ".tar.gz", ".*"), File.extname(t + "." + s)

# a local is held across the call, as before
h = yih(3)
p h.each_key.to_a, h.each_value.to_a
n = s + ".rb"
p File.extname(n), File.basename(n, ".rb")
