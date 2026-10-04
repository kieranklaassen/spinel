# The same one name further on: a local written from the `for` variable.
a = [+"q", +"r"]
for s in a
  u = s
  u << "x"
end
p a
