# Where the program gives a class a to_a of its own, a splat in values_at
# on a boxed receiver is read as it was: an Integer whose to_a answers none
# spreads to none.

class Integer
  def to_a = []
end
a = [[10, 20, 30], nil][ARGV.size]
i = ARGV.size + 1
p a.values_at(0, *i)
p a.values_at(0, *[2])
