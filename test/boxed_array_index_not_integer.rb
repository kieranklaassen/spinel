# The index of an Array converts as an Integer argument does: a Float is cut,
# and true, false, an Array or a Hash is a TypeError. Through a boxed
# receiver each read element 0.

def pick(n) = n > 0 ? {a: 1} : [10, "s", :z]

def report
  p yield
rescue TypeError => e
  puts "TypeError: #{e.message}"
end

h = pick(0)
report { h[1.5] }
report { h[-1.2] }
report { h[Rational(3, 2)] }
report { h[true] }
report { h[false] }
report { h[[0]] }
report { h[{a: 1}] }
report { h.at(1.5) }
report { h.at(true) }

# the index boxed too
k = [true, 0][0]
report { h[k] }
f = [1.9, 0][0]
report { h[f] }

begin
  h[true] ||= 1
rescue TypeError => e
  puts "TypeError: #{e.message}"
end
p h

# an object that converts
class Ix
  def to_int = 2
end
report { h[Ix.new] }

# an Integer, a Range and nil answer as before, and so does a Hash keyed by
# a Float, true or an Array
p h[0]
p h[-1]
p h[0..1]
report { h[nil] }
g = [{1.5 => :f, true => :t, [0] => :a}, 5][0]
p g[1.5]
p g[true]
p g[[0]]
