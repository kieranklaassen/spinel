# append_as_bytes answers its receiver (CRuby 3.4 and later), so a mutator
# on its result changes the variable too.
t = +"abcd"
t.append_as_bytes("y") << "x"
p t
t = +"abcd"
t.append_as_bytes("y").concat("x").upcase!
p t
t = +"abcd"
t.clear.append_as_bytes("y").concat("z")
p t
t = +"abcd"
t.append_as_bytes("y").clear
p t
t = +"abcd"
t.append_as_bytes("y").slice!(0)
p t
