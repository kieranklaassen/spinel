# A splat of a value that is no Array, Hash, Range or Enumerator makes a
# one-element Array of it at run time. When nothing else holds the value yet
# (an object or a String a call has just answered), it has to stay alive
# while that Array is allocated: run under SPINEL_GC_STRESS=2
# (make gc-stress-test) the collector reached the freed value.
class Tag
  def initialize(n) = @n = n
  def inspect = "#<Tag #{@n}>"
  def to_s = "tag#{@n}"
end
def tag(n) = Tag.new(n)
def str(n) = "s" + n.to_s

a = [0, "s"]
a.push(*tag(1))
a.push(*str(2))
p a

b = [0, "s"]
b.unshift(*str(3))
b.append(*tag(4))
b.prepend(*str(5))
b.insert(1, *str(6))
p b

def first_tag(xs)
  xs.each { |e| break *tag(e) }
end
def first_str(xs)
  xs.each { |e| break *str(e) }
end
p first_tag([7, 8])
p first_str([9, 10])

c = [1, 2, 3].map { |e| next *str(e) }
p c

d = [0, "s"]
20.times { |k| d.push(*str(k)) }
p d.size, d.last

# p, puts and print hand a splatted value to the same wrapper
p(*tag(11))
puts(*tag(12))
print(*tag(13), "\n")
p(*str(14))
puts(*str(15))
i = 0
p(*tag(16), (i += 1))
puts(*str(17), (i += 1))
print(*str(18), (i += 1), "\n")
