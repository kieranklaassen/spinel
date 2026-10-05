# The same through `store`, two methods deep, into an appending pair block.
def put(h, k, v); h.store(k, v); end
def fill(h, k, v); put(h, k, v); end
h = {}
fill(h, :a, +"q")
h.each_pair { |k, x| x << "!" }
p h
