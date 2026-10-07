# A value object is built in a struct of its constructor's own, or of the call
# site's where initialize takes a block, and no root reaches that struct: a
# String initialize has written has to live through what initialize allocates
# next.
#
# Each line is the number of objects, of 1,500, that read back something else.
class Two
  def initialize(r)
    @a = "abc" * r
    @s = "hello world " * r
  end
  def bad? = @a != "abc" * 240 || @s.length != 2880
end

class Three
  def initialize(r)
    @a = "abc" * r
    @s = "hello world " * r
    @z = "zed" * r
  end
  def bad? = @a != "abc" * 240 || @s != "hello world " * 240 || @z.length != 720
end

class Counted
  def initialize(r)
    @n = r
    @a = "abc" * r
    @s = @a + "!"
  end
  def bad? = @n != 240 || @a != "abc" * 240 || @s.length != 721
end

def tail_of(r) = "hello world " * r

class Called
  def initialize(r)
    @a = "abc" * r
    @s = tail_of(r)
  end
  def bad? = @a != "abc" * 240 || @s.length != 2880
end

class Either
  def initialize(r)
    @a = "abc" * r
    if r > 100
      @s = "hello world " * r
    else
      @s = "short"
    end
  end
  def bad? = @a != "abc" * 240 || @s.length != 2880
end

class Yielded
  def initialize(r)
    @a = "abc" * r
    @s = yield r
  end
  def bad? = @a != "abc" * 240 || @s.length != 2880
end

class Blocked
  def initialize(r, &blk)
    @a = "abc" * r
    @s = blk.call(r)
  end
  def bad? = @a != "abc" * 240 || @s.length != 2880
end

class Lone
  def initialize(r)
    @s = "hello world " * r
  end
  def bad? = @s != "hello world " * 240
end

class Last
  def initialize(r)
    @n = r
    @s = "hello world " * r
    @m = r
  end
  def bad? = @n != 240 || @s != "hello world " * 240 || @m != 240
end

def count
  bad = 0
  1500.times { bad += 1 if yield }
  bad
end

puts "two Strings: #{count { n = Two.new(240); n.bad? }}"
puts "three Strings: #{count { n = Three.new(240); n.bad? }}"
puts "a String built from a field: #{count { n = Counted.new(240); n.bad? }}"
puts "a String from a method: #{count { n = Called.new(240); n.bad? }}"
puts "a String under a condition: #{count { n = Either.new(240); n.bad? }}"
puts "a String from the block: #{count { n = Yielded.new(240) { |r| "hello world " * r }; n.bad? }}"
puts "a String from a block parameter: #{count { n = Blocked.new(240) { |r| "hello world " * r }; n.bad? }}"
puts "one String: #{count { n = Lone.new(240); n.bad? }}"
puts "Integers after the String: #{count { n = Last.new(240); n.bad? }}"
