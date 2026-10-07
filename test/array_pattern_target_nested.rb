# A bare target inside a nested pattern takes a value that arrives boxed:
# an element of a nested Array pattern, a nested rest, the value of a Hash
# pattern under an Array pattern. A local that an assignment also writes kept
# the assignment's type, and the value was read at that type: a String local
# took a Symbol's bits and the program crashed, an Integer local read a
# String as 0.

# an element of a nested Array pattern into a String local
nested = [[:q, :r], 9]
t = "o"
case nested
in [[t, _], _]
  p t
end
p t

# after the nested pattern's splat; a nested pattern after the outer splat
u = 0
case [["a", "b"], 9]
in [[_, *, u], _]
  p u
end
w = :o
case [9, [1.5, 2]]
in [*, [w, _]]
  p w
end
puts "#{u} #{u.class}", w == 1.5

# a nested rest
r = "o"
case [[1, 2, 3], 9]
in [[_, *r], _]
  p r
end
puts "#{r.inspect} is #{r.class}"

# two levels down, and inside a find pattern's window
d = "o"
case [[[7]], 9]
in [[[d]], _]
  p d
end
f = "o"
case [9, [:x, :y], 8]
in [*, [f, _], *]
  p f
end
p d, f

# the value of a Hash pattern under an Array pattern
h = 0
case [[{k: "v"}], 9]
in [[{k: h}], _]
  p h
end
g = "o"
case [9, {k: :v}]
in [*, {k: g}]
  p g
end
p h, g

# the nested pattern is captured as well
c = 0
case [["a", "b"], 9]
in [[c, _] => pair, _]
  p c, pair
end

# the element is of the class the local held
m = "o"
case [[1, "s"], 9]
in [[_, m], _]
  p m
end
p m == "s"

# in a method that takes Arrays of several kinds; a comparison is its answer
def first_of(rows)
  x = "none"
  case rows
  in [[x, *], _]
    puts "matched"
  else
    puts "no"
  end
  puts "#{x.inspect} is #{x.class}"
  x == :q
end
p first_of([[:q, :r], 9]), first_of([[1.5], "z"]), first_of([7])

# two arms, in a loop; no match leaves the earlier value
rows = [[[:a, :b], 1], [[1, "s", 2.5], 2], [nil, 3]]
v = "o"
k = 0
while k < 3
  case rows[k]
  in [[_, v], _]
    p v
  in [[_, *, v], _]
    p v
  else
    p :no
  end
  k += 1
end
p v

# `in` and `=>` as expressions
e = "o"
ok = ([[:q], 9] in [[e], _])
p ok, e
j = 0
[[:q, 1], 9] => [[j, _], _]
p j

# The local is typed by the pattern only where every other use of it prints
# or compares it. Each of these does more with it, and keeps the type it
# had: the element here is a String, as the local is.
class Box
  attr_reader :v
  def initialize(v) = (@v = v)
end
b1 = "o".dup
case [[1, "s".dup], 9]
in [[_, b1], _] then puts "hit"
end
held = [b1]
held[0] << "y"
p b1
b2 = "o".dup
case [[1, "s".dup], 9]
in [[_, b2], _] then puts "hit"
end
box = Box.new(b2)
box.v << "m"
p b2
b3 = "o"
case [[1, "s"], 9]
in [[_, b3], _] then puts "hit"
end
p b3.upto("u").to_a
b4 = "o"
case [[1, "s"], 9]
in [[_, b4], _] then puts "hit"
end
p b4.equal?(b4), !b4
