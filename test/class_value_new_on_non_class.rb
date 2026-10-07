# `new` on a boxed value that is no class is an ordinary method call: it
# raises NoMethodError, or calls the value's own `new`. The value carries a
# class id all the same (nil reads as 0, an instance as its class's), and
# the dispatch on that id built an object: `r.new` on a nil r answered an
# instance of the program's first class.

class Box
  def initialize(a = 0)
    @a = a
  end
  attr_reader :a
end

class Run
  def initialize
    @a = yield
  end
  attr_reader :a
end

class Cup; end

# an instance that answers `new` itself
class Maker
  def new(a = 0) = Box.new(a + 100)
end

class Holder
  def initialize(k)
    @k = k
  end

  def build = @k.new.class
end

def make(k) = k.new(4).a

c = ARGV.size > 5

# a local out of a conditional, either side taken
r = c ? Box : nil
begin
  p r.new.class
rescue NoMethodError => e
  puts e.message
end
k = c ? nil : Box
p k.new.class

# `c && Box` is false
f = c && Box
begin
  p f.new.class
rescue NoMethodError => e
  puts e.message
end

# an element of an Array, each kind of value beside the class
[Box, nil, false, 5, 2.5, "x", :sym, [1], Box.new, Cup.new].each do |v|
  begin
    p v.new.class
  rescue NoMethodError => e
    puts e.message
  end
end

# a key the Hash does not hold
reg = { "box" => Box }
begin
  p reg["nope"].new.class
rescue NoMethodError => e
  puts e.message
end
p reg["box"].new.class

# a parameter and an instance variable
p make(Box)
begin
  p make(nil)
rescue NoMethodError => e
  puts e.message
end
p Holder.new(Box).build
begin
  p Holder.new(Box.new).build
rescue NoMethodError => e
  puts e.message
end

# with an argument and with a block; the argument is evaluated first
def tick(n)
  puts "tick #{n}"
  n
end
[Box, nil].each do |v|
  begin
    p v.new(tick(6)).a
  rescue NoMethodError => e
    puts e.message
  end
end
begin
  r.new(Integer("zz"))
rescue ArgumentError
  puts "bad number"
end
[Run, 5].each do |v|
  begin
    p v.new { 9 }.a
  rescue NoMethodError => e
    puts e.message
  end
end

# the safe call on nil still answers nil
p r&.new.class

# a keyword, a splat and an argument beside a block take the same road
class Opt
  def initialize(a: 0)
    @a = a
  end
  attr_reader :a
end
xs = [3]
[Opt, Box, nil, 5].each do |v|
  begin
    p v.new(a: 1).a.class
  rescue NoMethodError, ArgumentError => e
    puts e.class
  end
  begin
    p v.new(*xs).a
  rescue NoMethodError, ArgumentError => e
    puts e.class
  end
end

# the value's own `new` is called, with the arguments it is given
ks = [Box, Maker.new, Box, 7]
ks.each do |v|
  begin
    p v.new(1).a
  rescue NoMethodError => e
    puts e.message
  end
end
p ks[1].new.a, ks[1].new(tick(2)).a
p ks[1].new(ks.map { |v| v.is_a?(Class) ? 1 : 0 }.sum).a
