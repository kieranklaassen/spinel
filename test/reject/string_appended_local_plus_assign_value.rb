# The VALUE of `t += "x"` on a String local that is also appended to: the
# write gives t a new String, and v would have to be that same String, so
# that the append below shows through both names. Nothing pairs the two
# here, so it is refused; as a statement the write compiles
# (test/string_appended_local_plus_assign.rb).
s = +""
t = s << "a" << "b"
v = (t += "x")
t << "!"
p s, t, v
