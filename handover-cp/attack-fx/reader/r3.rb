class W; def initialize; @n = 0; end; def n; @n; end; def then; :own; end; end
def pick(f) = f ? W.new : nil
b = pick(false)
r = b.then
p r.class
