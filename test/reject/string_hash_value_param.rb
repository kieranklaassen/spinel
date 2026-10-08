# The Hash is a parameter: its stores are the caller's.
def bump(h); h.each { |k, x| x << "!" }; end
h = {}
h[:a] = +"q"
bump(h)
p h
