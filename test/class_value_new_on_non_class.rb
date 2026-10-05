# `new` on a boxed value that is no class raises NoMethodError. The value
# carries a class id all the same (nil reads as 0, an instance as its
# class's), and the dispatch on that id built an object: `r.new` on a nil
# r answered an instance of the program's first class.

class Box
  def initialize(a = 0)
    @a = a
  end
  attr_reader :a
end

class Key
  def initialize(a:)
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

# with an argument, a keyword, a block and a splat
xs = [7]
[Box, nil].each do |v|
  begin
    p v.new(6).a
    p v.new(*xs).a
  rescue NoMethodError => e
    puts e.message
  end
end
[Key, nil].each do |v|
  begin
    p v.new(a: 8).a
  rescue NoMethodError => e
    puts e.message
  end
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
