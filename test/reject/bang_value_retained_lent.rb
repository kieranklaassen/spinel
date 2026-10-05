# The kept value handed to a method that appends to its parameter is
# changed in place there: refused as an append through the local is.
def add(x)
  x << " and a tail long enough to move the buffer"
end
s = +"az"
r = s.succ!
add(r)
p s
