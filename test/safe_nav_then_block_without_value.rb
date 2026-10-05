# `o&.then { ... }` whose block has no value of its own to type: it answers
# nil, or it only returns from the method, or it only raises. Written inline
# such a result is carried boxed, and the nil test beside it answered a bare
# 0: the two arms disagreed and the C did not build.

class K
  attr_accessor :v
  def initialize(v = 3) = (@v = v)
end

def mk(v) = v ? K.new : nil
def ms(v) = v ? "ab" : nil
def mi(v) = v ? 12 : nil

$log = []
def lg(x) = ($log << x; x)

# the block answers nil: an object, a String, an Integer; there and nil
o = mk(true)
x = o&.then { |y| lg(y.v); nil }
p x
o = mk(false)
x = o&.then { |y| lg(:no); nil }
p x
s = ms(true)
p(s&.then { |y| lg(y); nil })
s = ms(false)
p(s&.then { |y| lg(:no); nil })
i = mi(true)
p(i&.then { |y| lg(y); nil } || :none)
i = mi(false)
p(i&.then { |y| lg(:no); nil } || :none)
p $log

# the block only returns from the method
def early(o)
  o&.then { |y| return :early }
  :late
end
p early(mk(true)), early(mk(false))

def early_s(s)
  s&.then { |y| return y + "!" }
  "late"
end
p early_s(ms(true)), early_s(ms(false))

# the block only raises
def boom(o)
  o&.then { |y| raise "boom #{y.v}" }
  :quiet
rescue => e
  e.message
end
p boom(mk(true)), boom(mk(false))
