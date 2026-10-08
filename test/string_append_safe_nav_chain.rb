# A chained append whose first link is a safe-navigation call appends each
# operand once. The statement tests that link's answer for nil, which runs
# it, and the chain was then walked through it again: "a" was appended
# twice and its operand ran twice.
def chain
  t = +"4"
  t << "2"
  t&.<<("a") << "b"
  t
end

def concat
  t = +"4"
  t << "2"
  t&.concat("c").concat("d")
  t
end

def three
  t = +"4"
  t << "2"
  t&.<<("a") << "b" << "c"
  t
end

def mixed
  t = +"4"
  t << "2"
  t&.concat("a") << "b"
  t
end

# the first operand runs once
def counted
  t = +"4"
  t << "2"
  n = 0
  t&.<<((n += 1).to_s) << "b"
  [t, n]
end

# as its method's value
def tail
  t = +"4"
  t << "2"
  t&.<<("a") << "b"
end

def id(x) = x

# operands that are calls
def calls
  t = +"4"
  t << "2"
  t&.<<(id("a")) << id("b")
  t
end

# a String local that is no handle appended each operand once already
def plain
  t = +"x"
  t&.<<("a") << "b"
  t
end

def plain_calls
  t = +"x"
  t&.<<(id("a")) << id("b")
  t
end

# a nil receiver: the first link answers nil, and nil has no <<
def none(c)
  t = +"4"
  t << "2"
  t = nil if c
  t&.<<("a") << "b"
  t
end

p chain
p concat
p three
p mixed
p counted
p tail
p calls
p plain
p plain_calls
p none(false)
begin
  p none(true)
rescue NoMethodError
  puts "NoMethodError"
end

u = +"x"
u&.<<(id("a")) << id("b")
p u
v = +"x"
v&.<<("a") << "b"
p v
