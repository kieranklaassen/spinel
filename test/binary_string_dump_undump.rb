# dump and undump answer in their receiver's encoding. A binary String
# has no characters past ASCII, so dump writes each such byte as \xHH
# (not the \u form of a character it does not hold), and the dump is
# binary too. undump of a binary dump is binary, unless the dump holds
# a \u escape, which makes the answer UTF-8.

def id(s) = s

# the dump is printed with / for each of its backslashes
def show(x)
  d = x.dump
  u = d.undump
  puts d.tr("\\", "/")
  p [d.encoding.to_s, u.encoding.to_s, u.bytes, u == x, u.valid_encoding?]
end

show(id("=".b))
show(id("a\xC3\xA9".b))
show(id("\xFF\x00=".b))
show(id("="))
show(id("a\xC3\xA9"))
show(id("".b))

# the length counts bytes once the mark is kept
p id("a\xC3\xA9".b).dump.undump.size
p id("a\xC3\xA9").dump.undump.size

# undump alone: the dump's own encoding, or UTF-8 for a \u escape
p id("\"\\xC3\\xA9\"".b).undump.encoding.to_s
p id("\"\\xC3\\xA9\"").undump.encoding.to_s
p id("\"/u00e9\"".tr("/", "\\").b).undump.encoding.to_s
p id("\"abc\"".b).undump.encoding.to_s
p id("\"\\xC3\\xA9\"".b).undump.size

# a receiver held in a mixed Array
a = [id("a\xC3\xA9".b), 1]
puts a[0].dump.tr("\\", "/")
p a[0].dump.encoding.to_s, a[0].dump.undump.encoding.to_s

# the answer goes on as a binary String
r = id("\xC3\xA9=".b).dump.undump
p r.reverse.bytes, r.chars.size, (r + "x").encoding.to_s
