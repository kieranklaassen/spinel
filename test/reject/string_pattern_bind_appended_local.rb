# A pattern binds the SUBJECT ITSELF to the local: the same String, not a
# copy. `t` is appended to in place, so it holds its String in a buffer of
# its own; the plain String `line` cannot be that buffer, and a copy would
# part the two (the append below would not show in `line`). Refused, where
# the C did not build.
line = +"zz"
t = +""
t << "a"
case line
in String => t
  t << "!"
end
p line, t
