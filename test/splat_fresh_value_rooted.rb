# A splat of a value that is no Array, Hash, Range or Enumerator makes a
# one-element Array of it at run time. When nothing else holds the value yet
# (an object, a String or a big Integer a call has just answered), it has to
# stay alive while that Array is allocated: run under SPINEL_GC_STRESS=2
# (make gc-stress-test) the collector reached the freed value.
class Tag
  def initialize(n) = @n = n
  def inspect = "#<Tag #{@n}>"
end
def tag(n) = Tag.new(n)
def str(n) = "s" + n.to_s
def big(n) = 2**70 + n

a = [0, "s"]
a.push(*tag(1))
a.push(*str(2))
a.push(*big(3))
p a

b = [0, "s"]
b.unshift(*str(4))
b.append(*tag(5))
b.prepend(*big(6))
b.insert(1, *str(7))
p b

def first_tag(xs)
  xs.each { |e| break *tag(e) }
end
def first_str(xs)
  xs.each { |e| break *str(e) }
end
p first_tag([8, 9])
p first_str([10, 11])

c = [1, 2, 3].map { |e| next *str(e) }
p c

d = [0, "s"]
20.times { |k| d.push(*str(k)) }
p d.size, d.last
