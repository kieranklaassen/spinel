# A `return` whose value is a `yield`, or a conditional one of whose arms
# is a `yield`, in a method called with blocks that answer different
# types: each call answers its own block's value. The return joined the
# method's type with the first site's block, and a later site's value was
# converted to it: `fetched(true) { 9 }` below answered :"" for 9.
def fetched(c)
  return yield if c
  :none
end
p fetched(true) { :s }
p fetched(true) { 9 }
p fetched(false) { 0 }

def chosen(c)
  return (c ? yield : :none)
end
p chosen(true) { :s }
p chosen(true) { 9 }
p chosen(false) { 0 }

def guarded
  return (yield rescue :rescued)
end
p guarded { :s }
p guarded { 9 }
p guarded { raise "no" }

def fallback
  return yield || "none"
end
p fallback { "s" }
p fallback { 9 }
p fallback { nil }

def handed
  return yield
end
p handed { :s }
p handed { "s" }
p handed { 9 }

# from inside a block of the method, and in an instance method
def found(list)
  list.each { |x| return yield(x) if x > 1 }
  nil
end
p found([1, 2, 3]) { |x| x * 10 }
p found([1, 2, 3]) { |x| "x#{x}" }
p found([0, 1]) { |x| x }

class Box
  def initialize(on)
    @on = on
  end

  def take
    return (@on ? yield : 1.5)
  end
end
p Box.new(true).take { "s" }
p Box.new(true).take { [1, 2] }
p Box.new(false).take { 0 }

# a yield that ends a parenthesized sequence is left as it was
def mark(seen)
  seen << :in
  0
end

def noted(seen)
  return (mark(seen); yield) || 5
end
seen = []
p noted(seen) { true }
p noted(seen) { nil }
p seen

# blocks whose values one slot holds are left as they were, unboxed
def held(c)
  return (c ? yield : 5)
end
i = 0
t = 0
while i < 11000
  a = held(i.odd?) { i }
  t += a * 2 + 1 if a > 3
  i += 1
end
p held(true) { nil }
p t

# but not a Symbol's slot under `return yield`: a nil block's value came
# out there as a Symbol
def named(c)
  return yield if c
  :none
end
p named(true) { :s }
p named(true) { nil }
p named(false) { nil }
