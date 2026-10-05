# A String variable in an Array literal bound to a parameter the method
# yields with a splat: the block's parameter is a copy of the element, so
# its append would not reach the caller's String.
def run(a) = yield(*a)
s = +"a"
run([s]) { |k| k << "x" }
p s
