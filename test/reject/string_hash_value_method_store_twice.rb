# The store is two calls away, and the call ahead of it hands the same
# methods a literal.
def fill(h, k, v); h[k] = v; end
def outer(h, k, v); fill(h, k, v); end
h = {}
outer(h, :a, "lit")
outer(h, :b, +"q")
h.each_value { |x| x << "!" unless x.frozen? }
p h
