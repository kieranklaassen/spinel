# `s += x` reads s as `s = s + x` does: the String copied into the global
# is read by the operator write after the append.
def tag
  s = +"az"
  $last = s
  $last << "!"
  s += "?"
end
p tag
