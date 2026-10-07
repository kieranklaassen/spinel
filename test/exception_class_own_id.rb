# The class of an exception is the program's own class where the program
# defines it: its `new` and its own methods answer, wherever the class sits
# among the program's classes and however the exception was rescued.

class First < StandardError
  def self.build = new("b")
  def extra = 1
end

class Plain
  def hi = 1
end

class Second < StandardError
  def self.build = new("c")
  def extra = 2
end

class Sub < Second
  def extra = 3
end

module M
  class Nested < StandardError
    def extra = 4
  end
end

# the program's first class
begin
  raise First, "m"
rescue => e
  k = e.class
  p k, k == First, k.build.message, k.new("z").extra
end

# a later one
begin
  raise Second, "m"
rescue => e
  k = e.class
  p k, k == Second, k.build.message, k.new("z").extra
end

# rescued by its own name, and held past the rescue
held = nil
begin
  raise Second, "m"
rescue Second => e
  held = e.class
  p e.class.build.message
end
p held, held.new("z").extra, held.new("z").message

# a subclass rescued by its parent is the subclass
begin
  raise Sub, "m"
rescue Second => e
  k = e.class
  p k, k == Sub, k == Second, k.new("z").extra, k.superclass
end

# a class in a module
begin
  raise M::Nested, "m"
rescue => e
  p e.class, e.class.new("z").extra
end

# through $!
begin
  raise First, "m"
rescue
  p $!.class.build.message, $!.class.new("z").extra
end

# as a Hash key beside the constant
h = { First => 1, Second => 2 }
begin
  raise Second, "m"
rescue => e
  p h[e.class], h.key?(e.class)
end

# an exception class the program does not define is still that class
begin
  raise ArgumentError, "m"
rescue => e
  p e.class, e.class == ArgumentError, e.class == First
  p e.class.new("z").message
end
