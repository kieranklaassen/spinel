# A pattern binds the SUBJECT ITSELF to the local: the same String, not a
# copy. A local that is also appended to holds its String by a handle, a
# plain String subject has none to give, and a new handle would part the
# two (the append below would not show in `line`). Refused, where the C
# did not build.
line = +"zz"
t = +""
t << "a"
case line
in String => t
  t << "!"
end
p line, t
