# spinel: int64
# A big Integer has no to_a either: splatted into a yield, a proc or a lambda
# it is the one argument, as a small one is (splat_one_value_into_block.rb).
def one(v) = yield(*v)

big = 2**70
la = lambda { |a| a }
rest = proc { |*r| r }
p(one(big) { |a| a })
p(one(2**70 + 1) { |a, b| [a, b] })
p la.call(*big)
p rest.call(*big)

# boxed
x = [big, 1][0]
p rest.call(*x)
p(one(x) { |a| a })
