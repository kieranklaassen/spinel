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
# a later argument that changes what an earlier splat reads runs first here,
# so that splat is read as it was: a scalar, a Range, a global a method
# sets, and a later splat that does it
j = ARGV.size == 0 ? nil : 1
p a.values_at(*j, (j = 1; 0))
r2 = (2..1)
p a.values_at(*r2, (r2 = (0..1); 2))
$j = nil
def setj = ($j = 1; 0)
p a.values_at(*$j, setj)
j = ARGV.size == 0 ? nil : 1
p a.values_at(*j, *(j = 1; [0]))
# a scalar that is nil when the call runs spreads to none
n = ARGV.size == 0 ? nil : 1
p a.values_at(*n)
ia = [1, 2]
p a.values_at(0, *ia[5])
def maybe(k) = k > 0 ? 1 : nil
p a.values_at(*maybe(0), 2)
f = ARGV.size == 0 ? nil : 1.5
p a.values_at(*f, 2)
t = ARGV.size == 0 ? nil : "ab"
p a.values_at(*t&.size)
# a Range that excludes its end and has no members
p a.values_at(0, *(1...1))

# a boxed Hash takes the same list
h = [{1 => :x, 2 => :y}, nil][ARGV.size]
p h.values_at(*(1..2))
# ...where a key that is nil when the call runs is none as well, and so is
# one that a parameter left out or an index into a MatchData
hs = [{ "a" => 1, nil => 7 }, nil][ARGV.size]
k = ARGV.size == 0 ? nil : "b"
p hs.values_at("a", *k)
def pickv(h, k = nil) = h.values_at("a", *k)
p pickv(hs, "a")
p pickv(hs)
m = ["abc".match(/(a)(b)(c)/), nil][ARGV.size]
p m.values_at(1, *n)

# an Array spreads as before
p a.values_at(*[0, 2])
x = [[2, 0], nil][ARGV.size]
p a.values_at(*x)
def at_rest(a, *i) = a.values_at(*i)
p at_rest(a, 2, 1)
