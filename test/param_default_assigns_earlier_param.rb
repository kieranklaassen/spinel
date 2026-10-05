# A parameter default that assigns an EARLIER parameter of its method. The
# callee runs such a default itself (param_default_assigns_local_read_by_body)
# and declares the locals the default assigns nil ahead of the body. A
# parameter is bound on entry, so it is not one of them: declared nil, the
# earlier parameter lost its argument whenever the default was not taken.

def pair(a, b = (a = 9; 3))
  [a, b]
end
p pair(1)
p pair(1, 2)

# the default reads the parameter it assigns
def bump(a, b = (a += 1))
  [a, b]
end
p bump(1)
p bump(1, 5)

# `||=` keeps an argument that was given
def fill(a, b = (a ||= 9))
  [a, b]
end
p fill(nil)
p fill(1)
p fill(1, 5)

# a keyword default, a String
def label(name, sep: (name = "anon"; "-"))
  name + sep
end
puts label("ann")
puts label("ann", sep: ":")

# an earlier optional parameter, in an instance method
class Span
  def cut(from = 0, len = (from = 1; 2))
    [from, len]
  end
end
p Span.new.cut
p Span.new.cut(5)
p Span.new.cut(5, 6)

# a default that assigns its own parameter
def own(a, b = (b = 9; 3))
  [a, b]
end
p own(5)
p own(5, 7)

# beside a local of the default, which still starts nil
def both(a, b = (seen = true; a = 9; 3))
  [a, b, seen]
end
p both(1)
p both(1, 2)
