# sub and gsub with a String pattern and a Hash read the Hash's default
# for a pattern that is not a key, as CRuby's hash[match] does.
h = Hash.new("?")
h["q"] = "1"
p "abq".gsub("b", h)
p "abq".sub("b", h)
p "abq".gsub("q", h)
p "abqb".gsub("b", h)

m = { "b" => "x" }
m.default = "D"
p "abc".gsub("c", m)
p "abc".sub("c", m)
p "abc".gsub("b", m)
p "abc".gsub("z", m)

# a default that is not a String is read as its to_s
n = Hash.new(0)
n["x"] = 7
p "axb".gsub("b", n)
p "axb".sub("a", n)
p "axb".gsub("x", n)

v = Hash.new(:none)
v["x"] = 1
v["y"] = "s"
p "axyb".gsub("b", v)
p "axyb".sub("a", v)

# a pattern that holds a NUL byte
z = Hash.new("-")
z["k"] = "v"
p "a\0b\0".gsub("\0", z)
p "a\0b\0".sub("\0", z)

# no default: the pattern is cut out, as before
e = { "k" => "v" }
p "abc".gsub("b", e)
p "abc".sub("b", e)

# gsub! and sub! too
s = +"abqb"
s.gsub!("b", h)
p s
s = +"abqb"
s.sub!("b", h)
p s
