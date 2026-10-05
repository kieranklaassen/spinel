# `prepend A, B` puts A in front of B, as `include A, B` does: A's method
# is found first and its super reaches B's, then the class's own.
module Plain
  def hi = "plain " + super
end

module Fancy
  def hi = "fancy " + super
end

module Loud
  def hi = "loud " + super
end

class Both
  prepend Fancy, Plain
  def hi = "both"
end

class Each
  prepend Plain
  prepend Fancy
  def hi = "each"
end

class Three
  prepend Loud, Fancy, Plain
  def hi = "three"
end

class Then
  prepend Fancy, Plain
  prepend Loud
  def hi = "then"
end

class Under < Both
  def hi = "under " + super
end

# A module named again is prepended once, where its last naming puts it.
class Again
  prepend Fancy, Plain, Fancy
  def hi = "again"
end

class Swapped
  prepend Plain, Fancy
  prepend Fancy, Plain
  def hi = "swapped"
end

p Both.new.hi
p Both.ancestors.take(3)
p Each.new.hi
p Each.ancestors.take(3)
p Three.new.hi
p Three.ancestors.take(4)
p Then.new.hi
p Under.new.hi
p Again.new.hi
p Again.ancestors.take(3)
p Swapped.new.hi
p Swapped.ancestors.take(3)
