# A String Range held by a global, a constant, a class variable or a
# class-level instance variable keeps its two ends. The Range sits in the
# file-scope slot by value and carries two GC strings (#4353); the marker for
# those slots asked needs_root, which does not report a slot that is not
# itself a reference, so nothing marked the ends and the next collection
# freed them while the slot still named them.
#
# Every store below is made in a method that returns before anything
# allocates, so that the slot alone keeps the two ends.
def churn
  (1..200).map { |k| "j#{k}" }.size
end

$span = ("a".."z")
def fill_global(i)
  a = "a#{i}"
  z = "z#{i}"
  $span = (a..z)
end

bad = 0
i = 0
while i < 40
  fill_global(i)
  n = churn
  r = $span
  bad += 1 unless r.first == "a#{i}" && r.last == "z#{i}" && n == 200
  i += 1
end
puts "global: #{bad} #{$span.first}..#{$span.last}"

class Shelf
  @@span = ("a".."z")
  @span = ("a".."z")
  def self.put(a, z)
    @@span = (a...z)
    nil
  end
  def self.span = @@span
  def self.put_own(a, z)
    @span = (a..z)
    nil
  end
  def self.own = @span
end
def fill_cvar(i)
  a = "b#{i}"
  z = "y#{i}"
  Shelf.put(a, z)
end
def fill_own(i)
  a = "c#{i}"
  z = "x#{i}"
  Shelf.put_own(a, z)
end

bad = 0
i = 0
while i < 40
  fill_cvar(i)
  n = churn
  r = Shelf.span
  bad += 1 unless r.first == "b#{i}" && r.last == "y#{i}" && r.exclude_end? && n == 200
  i += 1
end
puts "class variable: #{bad} #{Shelf.span.first}...#{Shelf.span.last}"

bad = 0
i = 0
while i < 40
  fill_own(i)
  n = churn
  r = Shelf.own
  bad += 1 unless r.first == "c#{i}" && r.last == "x#{i}" && !r.exclude_end? && n == 200
  i += 1
end
puts "class ivar: #{bad} #{Shelf.own.first}..#{Shelf.own.last}"

# a constant is written once: its ends are made by a method that has returned
def pair(i)
  a = "d#{i}"
  z = "d#{i + 3}"
  (a..z)
end
LIMITS = pair(4)
churn
p LIMITS.first, LIMITS.last, LIMITS.to_a, LIMITS.cover?("d5")
