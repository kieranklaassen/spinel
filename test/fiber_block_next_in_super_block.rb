# A `next` in the block given to `super` leaves that block, also where the
# `super` is written in a Fiber.new, Thread.new or Enumerator.new block. The
# walk that says which `next` such a body owns stopped at the block of a
# call and went through the block of a `super`, so the `next` was written
# as the body's own and ended it: the first Fiber below answered 0, not
# [10, 0].
class Base
  def two
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end

  def from(n)
    r = []
    r << (yield n)
    r << (yield n + 1)
    r
  end

  def self.two
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end
end

# a super with parentheses, in a Fiber and in a Thread
class InFiber < Base
  def two
    f = Fiber.new do
      a = super() { |x| next 0 if x == 2; x * 10 }
      a
    end
    f.resume
  end
end
p InFiber.new.two

class InThread < Base
  def two
    Thread.new { a = super() { |x| next 0 if x == 2; x * 10 }; a }.value
  end
end
p InThread.new.two

# in a generator, beside a next of the generator's own
class InGenerator < Base
  def from(n)
    e = Enumerator.new do |y|
      a = super(n) { |x| next 0 if x == 2; x * 10 }
      y << a
      next if n == 1
      y << 9
    end
    e.to_a
  end
end
p InGenerator.new.from(1)
p InGenerator.new.from(5)

# a bare super, which hands the arguments on
class Bare < Base
  def from(n)
    Fiber.new { a = super { |x| next 0 if x == 2; x * 10 }; a }.resume
  end
end
p Bare.new.from(1)

# the block's next, the body's and an iterator's in one body
class Three < Base
  def two
    f = Fiber.new do
      a = super() { |x| next 0 if x == 2; x * 10 }
      next a.size if a.size > 5
      [1, 2].each { |v| next if v == 1; a << v }
      a
    end
    f.resume
  end

  def from(n)
    f = Fiber.new do
      a = super(n) { |x| next 0 if x == 2; x * 10 }
      next a.size if n == 1
      a
    end
    f.resume
  end
end
p Three.new.two
p Three.new.from(1)
p Three.new.from(5)

# a next with no value, in an if, in a case, with a String, as the whole block
class Shapes < Base
  def two
    f = Fiber.new do
      a = super() { |x| next if x == 2; x * 10 }
      b = super() { |x| if x == 2 then next 0 else x * 10 end }
      c = super() { |x| case x when 2 then next 0 end; x * 10 }
      d = super() { |x| next "z" if x == 2; "v#{x}" }
      e = super() { |x| next x * 3 }
      [a, b, c, d, e]
    end
    f.resume
  end
end
p Shapes.new.two

# the super as the body's value, and as the receiver of a call with a block
class Value < Base
  def two
    Fiber.new { super() { |x| next 0 if x == 2; x * 10 } }.resume
  end

  def from(n)
    Fiber.new { r = super(n) { |x| next 0 if x == 2; x * 10 }.map { |v| v + 1 }; r }.resume
  end
end
p Value.new.two
p Value.new.from(1)

# a next in an argument of the super is the body's
class Argument < Base
  def from(n)
    f = Fiber.new do
      a = super((next [7] if n == 0; n)) { |x| next 0 if x == 2; x * 10 }
      a
    end
    f.resume
  end
end
p Argument.new.from(0)
p Argument.new.from(1)

# an ensure in the body runs once, after the block was left twice
class Ensured < Base
  def two
    f = Fiber.new do
      begin
        a = super() { |x| next 0 if x == 2; x * 10 }
        a
      ensure
        puts "ensure"
      end
    end
    f.resume
  end
end
p Ensured.new.two

# the block yields from the Fiber before it leaves
class Yields < Base
  def two
    f = Fiber.new do
      a = super() { |x| Fiber.yield x; next 0 if x == 2; x * 10 }
      a
    end
    [f.resume, f.resume, f.resume]
  end
end
p Yields.new.two

# a Fiber in an iterator's block, and an iterator's block in a Fiber
class Nested < Base
  def two
    o = []
    [1, 4].each do |q|
      f = Fiber.new do
        a = super() { |x| next q if x == 2; x * 10 }
        a
      end
      o << f.resume
    end
    o
  end

  def from(n)
    f = Fiber.new do
      o = []
      [1, 4].each do |q|
        a = super(n) { |x| next q if x == 2; x * 10 }
        o << a
      end
      o
    end
    f.resume
  end
end
p Nested.new.two
p Nested.new.from(1)

# a class method
class OfClass < Base
  def self.two
    Thread.new { a = super() { |x| next 0 if x == 2; x * 10 }; a }.value
  end
end
p OfClass.two

# the block of delete asks the same walk whether it can keep its leading
# statements: it left them out for a `next` that is the super's block's
class InDelete < Base
  def two
    [1, 2].delete(9) { |k| a = super() { |x| next 0 if x == 2; x * 10 }; a.size + k }
  end
end
p InDelete.new.two
