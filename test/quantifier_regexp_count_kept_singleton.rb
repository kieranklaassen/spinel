# A `class << self` body is a frame of its own in CRuby and runs in the top
# level's here. A program that asks in one, or reads the registers in one,
# keeps asking every element.
class << self
  b = ["yb", "q"]
  p b.none?(/(.)b/)
end
p $~
a = ["xb", "q"]
p a.any?(/(.)b/)
class << self
  p $~
end
