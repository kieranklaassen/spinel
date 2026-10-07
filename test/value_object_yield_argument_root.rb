# A value object among a yield's arguments, or a call's keyword values, keeps
# its String.
#
# `yield Name.new(240), "ab" + "cd"` runs each value into a temp, so that the
# second cannot run ahead of the first; `m(n: Name.new(240), k: "ab" + "cd")`
# does the same. Name is laid out by value (a struct in the temp itself, no
# heap object), and the temp was rooted whole: that hands the collector the
# struct's first word, the class id, as a pointer, and leaves @s unheld while
# the second value is built. The String was freed and read back as another;
# with a class id that is not 0 the collector faulted.
#
# Each line is the number of rounds, of 2,000, that read back something else.

class Name
  def initialize(r) = @s = "hello world " * r
  def len(k) = @s.length + k.length
end

# an Integer ahead of the String
class Pair
  def initialize(n, r)
    @n = n
    @s = "hello world " * r
  end
  def len(k) = @n + @s.length + k.length
end

# no String: nothing in it to root
class Point
  def initialize(x, y)
    @x = x
    @y = y
  end
  def len(k) = @x + @y + k.length
end

def mk = Name.new(240)

def side(i)
  t = "x" * 300
  u = t + i.to_s
  u[0, 4]
end

def first_of_two
  yield Name.new(240), "ab" + "cd"
end

def between_two
  yield "ab" + "cd", Name.new(240), "ef" + "gh"
end

def in_a_block(i)
  [i].each do |_|
    yield Name.new(240), side(i)
  end
end

def from_a_method(i)
  yield mk, side(i)
end

def two_objects
  yield Name.new(240), Name.new(240), "ab" + "cd"
end

def by_keyword(n:, k:) = n.len(k)

def a_pair
  yield Pair.new(7, 240), "ab" + "cd"
end

def a_point
  yield Point.new(1, 2), "ab" + "cd"
end

bad = 0
2000.times { first_of_two { |n, k| bad += 1 unless n.len(k) == 2884 } }
puts "first of two: #{bad}"

bad = 0
2000.times { between_two { |a, n, k| bad += 1 unless n.len(k) + a.length == 2888 } }
puts "between two: #{bad}"

bad = 0
2000.times { |i| in_a_block(i) { |n, k| bad += 1 unless n.len(k) == 2884 } }
puts "in a block: #{bad}"

bad = 0
2000.times { |i| from_a_method(i) { |n, k| bad += 1 unless n.len(k) == 2884 } }
puts "from a method: #{bad}"

bad = 0
2000.times { two_objects { |n, m, k| bad += 1 unless n.len(k) == 2884 && m.len(k) == 2884 } }
puts "two objects: #{bad}"

bad = 0
2000.times { bad += 1 unless by_keyword(n: Name.new(240), k: "ab" + "cd") == 2884 }
puts "a keyword value: #{bad}"

bad = 0
2000.times { bad += 1 unless by_keyword(k: "ab" + "cd", n: Name.new(240)) == 2884 }
puts "a keyword value, written second: #{bad}"

bad = 0
2000.times { a_pair { |n, k| bad += 1 unless n.len(k) == 2891 } }
puts "an Integer and a String: #{bad}"

bad = 0
2000.times { a_point { |n, k| bad += 1 unless n.len(k) == 7 } }
puts "no String: #{bad}"
