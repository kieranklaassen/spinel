# A splatted Range is asked to_a, and that walks its each. Where the program
# names an each of its own, a splatted Range in values_at on a boxed receiver
# is read as it was: this each yields nothing, so the Range spreads to none.
# A splatted scalar asks no each.

class Range
  def each
    self
  end
end
a = [[10, 20, 30], nil][ARGV.size]
p a.values_at(*(0..1))
p a.values_at(0, *(1..2))
f = ARGV.size + 1.5
p a.values_at(0, *f)
