# A String a method stores into the Hash it was handed is the caller's
# Hash's: the value block that appends to it is refused, not given a copy.
def fill(h, k, v); h[k] = v; end
h = {}
fill(h, :a, +"q")
h.each_value { |x| x << "!" }
p h
