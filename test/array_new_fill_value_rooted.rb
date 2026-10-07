# Array.new(n, value) with a value made in place: the value is held while
# the Array it fills is made. Each line counts the Arrays, kept and made
# between other allocations, that do not hold their value.
class Pt
  attr_reader :v
  def initialize(v); @v = v; end
end
def pair(a); [a, a + a]; end

s = "abc"
t = "def"
u = "xyz"
k = 3

# a String: an Array of Strings
rows = []
3000.times do
  rows << Array.new(2, s + t)
  z = s + u
  z = u + s
end
puts "a String: #{rows.count { |r| r != ["abcdef", "abcdef"] }}"

# an interpolation
rows = []
300.times do
  rows << Array.new(2, "#{s}-#{t}")
  z = "#{u}-#{s}"
  z = "#{s}-#{u}"
end
puts "an interpolation: #{rows.count { |r| r != ["abc-def", "abc-def"] }}"

# a String a method answers, n a local
n = 2
rows = []
300.times do
  rows << Array.new(n, s.upcase)
  z = u.upcase
  z = t.upcase
end
puts "a method's String: #{rows.count { |r| r != ["ABC", "ABC"] }}"

# an object: an Array of mixed values
objs = []
300.times do
  objs << Array.new(2, Pt.new(s + t))
  z = Pt.new(s + u)
  z = Pt.new(u + s)
end
puts "an object: #{objs.count { |r| r[0].v != "abcdef" || r[1].v != "abcdef" }}"

# an Array a method answers
rows = []
300.times do
  rows << Array.new(2, pair(s))
  z = pair(u)
  z = pair(t)
end
puts "a method's Array: #{rows.count { |r| r != [["abc", "abcabc"], ["abc", "abcabc"]] }}"

# an empty Array
rows = []
300.times do
  rows << Array.new(2, [])
  z = [k]
  z = [k, k]
end
puts "an empty Array: #{rows.count { |r| r != [[], []] }}"

# a String or an Integer
rows = []
300.times do
  rows << Array.new(2, k > 2 ? s + t : k)
  z = s + u
  z = u + s
end
puts "a String or an Integer: #{rows.count { |r| r != ["abcdef", "abcdef"] }}"

# a String appended to in place, read
rows = []
300.times do
  b = +""
  b << s << t
  rows << Array.new(2, b)
  z = s + u
  z = u + s
end
puts "an appended String: #{rows.count { |r| r != ["abcdef", "abcdef"] }}"

# a Range, which is copied to the heap to enter an Array of mixed values,
# made in place and read from a local
r = (1..k)
rows = []
300.times do
  a = Array.new(2, (1..k))
  b = Array.new(2, r)
  rows << (a << nil) << (b << nil)
  z = (2..k + 4)
  y = [z, k]
end
puts "a Range: #{rows.count { |x| x[0] != (1..3) || x[1] != (1..3) }}"

# held already: a local, a literal, an Integer; and the block form
w = s + t
rows = []
300.times do
  rows << Array.new(2, w) << Array.new(2, "abcdef") << Array.new(2) { s + t }
  z = s + u
end
puts "held already: #{rows.count { |r| r != ["abcdef", "abcdef"] }}"
p Array.new(3, k + 1), Array.new(0, s + t), Array.new(1, s + t)
