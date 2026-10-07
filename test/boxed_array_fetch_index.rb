# fetch and values_at on a boxed Array take an index as fetch with a block
# does: anything that converts to an Integer, and nothing else. A Symbol, a
# String, true or a Float read element 0 or another wrong one.

def pick(n) = n > 0 ? {a: 1} : [10, "s", :z]

def report
  p yield
rescue TypeError, IndexError => e
  puts "#{e.class}: #{e.message}"
end

h = pick(0)
report { h.fetch(true) }
report { h.fetch(:a) }
report { h.fetch("a") }
report { h.fetch([0]) }
report { h.fetch(nil) }
report { h.fetch(1.5) }
report { h.fetch(-1.5) }
report { h.fetch(:a, 9) }
report { h.fetch(7.5) }
report { h.fetch(7.5, :dflt) }

report { h.values_at(true) }
report { h.values_at(:a) }
report { h.values_at("a") }
report { h.values_at(0, nil) }
report { h.values_at(1.5, 2) }

# an Integer and a Range answer as before, and so does a Hash
p h.fetch(0)
p h.fetch(-1)
p h.fetch(5, :dflt)
report { h.fetch(5) }
p h.values_at(0, 2, 5)
p h.values_at(0..1)
g = pick(1)
p g.fetch(:a)
p g.values_at(:a, :b)
report { g.fetch(:b) }
