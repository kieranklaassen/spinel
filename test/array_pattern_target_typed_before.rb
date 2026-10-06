# An Array pattern binds a local that an assignment also writes, to a
# value of another class. A captured element (`Integer => t`) and an
# element after the splat kept the assignment's type, and the element was
# read at that type: a String local took an Integer's bits and the program
# crashed, an Integer local read a String as 0.

# a captured element into a String local
t = "o"
case [3, "s"]
in [Integer => t, String]
  p t
end
p t

# into an Integer local
n = 0
case ["a", 4]
in [String => n, Integer]
  p n
end
p n

# an element after the splat, bare and captured
k = :o
case [1, 2, 3]
in [*, k]
  p k
end
f = 1.5
case [1, 2, "z"]
in [Integer, *, String => f]
  p f
end
p k, f

# every element is an Integer, the local was a String
w = "o"
case [3, 4]
in [Integer => w, Integer]
  p w + 1
end
p w * 2

# a Symbol local bound to an Integer: `s + 1` was refused as Symbol#+
s = :o
case [3, 4]
in [Integer => s, Integer]
  p s + 1
end

# a capture inside a nested pattern
a = "o"
c = :o
case [[3, "s"], [1, 2, 3], 7.5]
in [[Integer => a, String], [Integer, *], Float => c]
  p a, c
end
d = "o"
case [1, [1, 5, 2]]
in [*, [*, 5 => d, *]]
  p d
end
e = "o"
case [[3, "s"], 1]
in [[Integer, String] => e, Integer]
  p e
end

# two arms bind the local to different classes
rows = [[3, "s"], ["a", 4]]
v = 2.5
i = 0
while i < 2
  case rows[i]
  in [Integer => v, String]
    p v
  in [String => v, Integer]
    p v
  end
  i += 1
end
p v

# no match leaves the earlier value
g = "kept"
case [3, 4]
in [String => g, Integer]
  p g
else
  p :no
end
p g

# in a method, and what the method answers
def first_of(pair)
  x = "none"
  case pair
  in [Integer => x, String]
    x += 1
  in [*, Symbol => x]
    return x.to_s
  else
    return x.upcase
  end
  x
end
p first_of([3, "s"]), first_of([1, :z]), first_of([1.5])

# `in` and `=>` as expressions
h = "o"
r = ([3, "s"] in [Integer => h, String])
p r, h
j = "o"
[1, 2, :q] => [*, Symbol => j]
p j

# what an object deconstructs to
class Pair
  def initialize(l, r) = (@l = l; @r = r)
  def deconstruct = [@l, @r]
end
q = "o"
case Pair.new(3, "s")
in [Integer => q, String]
  p q
end
p q

# a capture of the class the local already holds reads it as before
m = 0
case [3, "s"]
in [Integer => m, String]
  p m + 1
end
u = "o"
case [3, "s"]
in [Integer, String => u]
  p u.upcase
end
