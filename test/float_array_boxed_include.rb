# A list of Floats behind a boxed value (a Hash value beside a String, a row
# of a mixed Array, the answer of a method of two kinds, a parameter or an
# instance variable that takes two kinds) asked include? or member? of a Float.
h = { prices: [9.5, 10.5], name: "x" }
p h[:prices].include?(9.5)
p h[:prices].include?(7.5)
p h[:prices].member?(10.5)

rows = [[1.5, 2.5], "total"]
p rows[0].include?(1.5)
p rows[0].include?(3.5)

def pick(n) = n > 0 ? [9.0, 10.5] : { a: 1 }
r = pick(1)
f = 10.5
p r.include?(f)
p r.include?(19.0 / 2)
p r.include?(18.0 / 2)
p r.member?(9.0)

def has?(c, x) = c.include?(x)
p has?([0.5, 1.5], 1.5)
p has?([0.5, 1.5], 2.5)
p has?({ 2.5 => 1 }, 2.5)

class Shelf
  def initialize(v) = @v = v
  def has?(x) = @v.include?(x)
end
p Shelf.new([0.5, 1.5]).has?(0.5)
p Shelf.new((1.0..2.0)).has?(1.5)
p Shelf.new((1.0..2.0)).has?(2.5)

# nil in the list, and a Float local that holds nil asked of it
g = { a: [9.5, nil], b: "s" }
nf = ARGV.empty? ? nil : 9.5
p g[:a].include?(9.5)
p g[:a].include?(nf)
p h[:prices].include?(nf)

# zero and its negative are equal; a NaN computed elsewhere is not in the list
z = { a: [0.0, 0.0 / 0.0], b: "s" }
p z[:a].include?(-0.0)
p z[:a].include?(0.0 / 0.0)
p z[:a].include?(0.5)
