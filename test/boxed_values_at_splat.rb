# A splat in the list of values_at on a boxed receiver spreads what it
# holds: a Range's members, nil's none, any other value as itself. It was
# read as an Array, so what was typed as no Array was empty and the call
# answered from the other indexes alone.

a = [[10, 20, 30], nil][ARGV.size]
p a.values_at(*(0..1))
r = (1..2)
p a.values_at(*r)
p a.values_at(0, *(1..2))
p a.values_at(*(0...2), 2)
p a.values_at(*(0..1), *(1..2))
p a.values_at(*nil)
p a.values_at(*2)
p a.values_at(*1, *(2..2))
def span = (0..1)
p a.values_at(*span)
# an end that needs a statement of its own, and one that changes a variable
p a.values_at(*(0..[1].size))
i = 0
p a.values_at(i, *((i += 1)..2), i)
begin
  p a.values_at(*(1..))
rescue RangeError => e
  puts "RangeError: #{e.message}"
end

# a boxed Hash takes the same list
h = [{1 => :x, 2 => :y}, nil][ARGV.size]
p h.values_at(*(1..2))

# an Array spreads as before
p a.values_at(*[0, 2])
x = [[2, 0], nil][ARGV.size]
p a.values_at(*x)
def at_rest(a, *i) = a.values_at(*i)
p at_rest(a, 2, 1)
