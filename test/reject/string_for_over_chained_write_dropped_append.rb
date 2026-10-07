# The same through the variable of a `for`.
b = a = [+"q", +"r"]
for s in a
  s << "!"
end
p b
