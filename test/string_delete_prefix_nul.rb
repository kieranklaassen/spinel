# String#delete_prefix and #delete_prefix! are byte-exact over a NUL, as
# #delete_suffix is: both measured the receiver and the prefix with strlen,
# so a receiver carrying a NUL lost its tail whether the prefix matched or
# not, and a prefix carrying one matched by its bytes before the NUL.

p "xa\0b".delete_prefix("x")
p "xa\0b".delete_prefix("x").bytesize
p "a\0b".delete_prefix("x")
p "a\0bc".delete_prefix("a\0b")
p "abc".delete_prefix("a\0zzz")
p "a\0b".delete_prefix("a\0b")
p "a\0b".delete_prefix("a\0c")
p "\0ab".delete_prefix("\0")
p "\0ab".delete_prefix("")
p "ab".delete_prefix("\0")

s = "xa\0b"
t = s.delete_prefix("x")
p t == "a\0b"
p t.size
p t + "!"
p t.bytes

# the bang form, as a statement and as a value
u = +"xa\0b"
u.delete_prefix!("x")
p u
p u.bytesize
v = +"a\0bc"
p v.delete_prefix!("a\0b")
p v
w = +"abc"
p w.delete_prefix!("a\0zzz")
p w
z = +"a\0b"
p z.delete_prefix!("q")
p z

# a String out of a slot that holds other kinds too
h = { 1 => "xa\0b", 2 => 3 }
p h[1].delete_prefix("x")

# a receiver that was appended to
b = +"x"
b << "a\0b"
p b.delete_prefix("x")
b.delete_prefix!("x")
p b

# no NUL: as before
p "hello".delete_prefix("he")
p "hello".delete_prefix("lo")
p "héllo".delete_prefix("hé")
