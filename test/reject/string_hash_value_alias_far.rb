# The same local, with the store in a method the Hash is handed to.
def fill(h, k, v); h[k] = v; end
h = {}
fill(h, :k, +"a")
h.each_value { |v| t = v; t << "!" }
p h
