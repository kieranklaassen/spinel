# The variable of a `for` over an Array whose Strings nothing has shared
# is a copy of each element. Appended to and read by nothing else, the
# copy is all that changes: refused, not lost.
a = [+"q", +"r"]
for s in a
  s << "!"
end
p a
