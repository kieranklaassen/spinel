# A String Range stored into an object that has survived a collection is
# recorded by the write barrier. The Range sits in the slot by value and
# carries two GC strings (#4353): the scan marked them, but the barrier did
# not count the slot as a reference, so a minor collection freed both ends
# while the old object still named them, and a later read answered with the
# bytes of whatever String took their place.
#
# Every store below is made in a method that returns before anything
# allocates, so that the holder alone keeps the two ends.
def churn
  (1..200).map { |k| "j#{k}" }.size
end

# a Struct member, through its writer
Span = Struct.new(:r)
def fill_member(s, i)
  a = "a#{i}"
  z = "z#{i}"
  s.r = (a..z)
end

s = Span.new(("a".."z"))
warm = (1..500).map { |k| "warm-#{k}" }
bad = 0
i = 0
while i < 40
  fill_member(s, i)
  n = churn
  r = s.r
  bad += 1 unless r.first == "a#{i}" && r.last == "z#{i}" && n == 200
  i += 1
end
puts "member: #{bad} #{s.r.first}..#{s.r.last}"

# an instance variable, written by a method and by an attribute writer
class Shelf
  attr_accessor :r
  def initialize(a, z)
    @r = (a..z)
  end
  def put(a, z)
    @r = (a...z)
    nil
  end
end
def fill_ivar(h, i)
  a = "b#{i}"
  z = "y#{i}"
  h.put(a, z)
end
def fill_attr(h, i)
  a = "c#{i}"
  z = "x#{i}"
  h.r = (a..z)
end

h = Shelf.new("a", "z")
bad = 0
i = 0
while i < 40
  fill_ivar(h, i)
  n = churn
  r = h.r
  bad += 1 unless r.first == "b#{i}" && r.last == "y#{i}" && r.exclude_end? && n == 200
  i += 1
end
puts "ivar: #{bad} #{h.r.first}...#{h.r.last}"

bad = 0
i = 0
while i < 40
  fill_attr(h, i)
  n = churn
  r = h.r
  bad += 1 unless r.first == "c#{i}" && r.last == "x#{i}" && !r.exclude_end? && n == 200
  i += 1
end
puts "attr: #{bad} #{h.r.first}..#{h.r.last}"

# initialize allocates first, so the object is old when it takes the Range
class Late
  attr_reader :r, :pad
  def initialize(i)
    @pad = churn
    a = "d#{i}"
    z = "w#{i}"
    @r = (a..z)
  end
end

bad = 0
i = 0
while i < 20
  l = Late.new(i)
  n = churn
  bad += 1 unless l.r.first == "d#{i}" && l.r.last == "w#{i}" && n == l.pad
  i += 1
end
puts "late: #{bad}"

# the Range still answers its own operations out of the slot
fill_member(s, 7)
churn
s.r = ("ab".."ae")
churn
p s.r.to_a, s.r.include?("ad"), s.r.cover?("b"), s.r.min, s.r.max
puts warm.size
