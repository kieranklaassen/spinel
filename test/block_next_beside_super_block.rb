# A block that is run in place (a tap block, the block of a yielding method,
# Array.new's block) and holds a `super` with a block of its own. A `next`
# in an argument of that super is the outer block's, with or without a
# `next` in the super's block; and a tap block is written as a loop when the
# super's block holds a `next`, which an `ensure` in the tap block's code
# leans on. None of this is in a Fiber, Thread or Enumerator body, and the
# walk that says which `next` such a body owns leaves all of it as it was.
def once
  yield
end

def twice(n)
  r = []
  r << (yield n)
  r << (yield n + 1)
  r
end

class Base
  def from(n)
    r = []
    r << (yield n)
    r << (yield n + 1)
    r
  end

  def maybe(n)
    r = []
    r << (yield n)
    r
  end

  def two
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end

  def guarded
    r = [yield(1)]
    begin
      r << (yield 2)
    ensure
      r << 9
    end
    r
  end

  def guarded_from(n)
    r = [yield(n)]
    begin
      r << (yield n + 1)
    ensure
      r << 9
    end
    r
  end
end

# a next in the super's argument, in a tap block
class ArgTap < Base
  def from(n)
    o = [8]
    0.tap do |q|
      a = super((next if n == 0; n)) { |x| x * 10 }
      o = a
    end
    o
  end
end
p ArgTap.new.from(0)
p ArgTap.new.from(1)

# in the block of a yielding method, a function's and the class's own
class ArgYielded < Base
  def from(n)
    once do
      a = super((next [7] if n == 0; n)) { |x| x * 10 }
      a
    end
  end
end
p ArgYielded.new.from(0)
p ArgYielded.new.from(1)

class ArgOwnYielder < Base
  def once2
    yield
  end

  def from(n)
    once2 do
      a = super((next [7] if n == 0; n)) { |x| x * 10 }
      a
    end
  end
end
p ArgOwnYielder.new.from(0)
p ArgOwnYielder.new.from(1)

# in Array.new's block: the element is the next's value
class ArgArrayNew < Base
  def from(n)
    Array.new(2) do |i|
      a = super((next [7] if i == 0; n)) { |x| x * 10 }
      a
    end
  end
end
p ArgArrayNew.new.from(1)

# the super's block holds a next too
class BothTap < Base
  def from(n)
    o = [8]
    0.tap do |q|
      a = super((next if n == 0; n)) { |x| next 0 if x == 2; x * 10 }
      o = a
    end
    o
  end
end
p BothTap.new.from(0)
p BothTap.new.from(1)

class BothYielded < Base
  def from(n)
    once do
      a = super((next [7] if n == 0; n)) { |x| next 0 if x == 2; x * 10 }
      a
    end
  end
end
p BothYielded.new.from(0)
p BothYielded.new.from(1)

class BothArrayNew < Base
  def from(n)
    Array.new(2) do |i|
      a = super((next [7] if i == 0; n)) { |x| next 0 if x == 2; x * 10 }
      a
    end
  end
end
p BothArrayNew.new.from(1)

# the super's block is a proc handed on, and the next is in the & expression
class AmpTap < Base
  def from(n)
    pr = proc { |x| x * 10 }
    o = [8]
    0.tap do |q|
      a = super((next if n == 0; n), &pr)
      o = a
    end
    o
  end
end
p AmpTap.new.from(0)
p AmpTap.new.from(1)

class AmpYielded < Base
  def from(n)
    pr = proc { |x| x * 10 }
    once do
      a = super((next [7] if n == 0; n), &pr)
      a
    end
  end
end
p AmpYielded.new.from(0)
p AmpYielded.new.from(1)

class AmpExpression < Base
  def from(n)
    pr = proc { |x| x * 10 }
    o = [8]
    0.tap do |q|
      a = super(n, &(next if n == 0; pr))
      o = a
    end
    o
  end
end
p AmpExpression.new.from(0)
p AmpExpression.new.from(1)

# the next is an arm of a conditional, and the right of an or
class ArgTernary < Base
  def from(n)
    once do
      a = super(n > 0 ? n : (next [7])) { |x| x * 10 }
      a
    end
  end
end
p ArgTernary.new.from(0)
p ArgTernary.new.from(1)

class ArgOr < Base
  def maybe(n)
    once do
      a = super(n || (next [7])) { |x| x * 10 }
      a
    end
  end
end
p ArgOr.new.maybe(nil)
p ArgOr.new.maybe(1)

# the block run in place is itself inside an each, and inside a while
class InsideEach < Base
  def from(n)
    o = []
    [0, 1].each do |q|
      v = once do
        a = super((next [7] if q == 0; q)) { |x| x * 10 }
        a
      end
      o << v
    end
    o
  end
end
p InsideEach.new.from(1)

class InsideWhile < Base
  def from(n)
    o = []
    i = 0
    while i < 2
      v = [8]
      0.tap do |q|
        a = super((next if i == 0; i)) { |x| x * 10 }
        v = a
      end
      o << v
      i += 1
    end
    o
  end
end
p InsideWhile.new.from(1)

# a tap block whose super's block holds a next, with an ensure in the parent
class EnsureInParent < Base
  def guarded
    o = [8]
    0.tap do |q|
      a = super() { |x| next 0 if x == 2; x * 10 }
      o = a
    end
    o
  end

  def guarded_from(n)
    o = [8]
    0.tap do |q|
      a = super { |x| next 0 if x == 2; x * 10 }
      o = a
    end
    o
  end
end
p EnsureInParent.new.guarded
p EnsureInParent.new.guarded_from(1)

# the super's value is not used
class EnsureUnused < Base
  def guarded
    n = 0
    5.tap do |q|
      super() { |x| next 0 if x == 2; n += x * q }
    end
    n
  end
end
p EnsureUnused.new.guarded

# the ensure is around the super, in the tap block and in a tap in a tap
class EnsureAround < Base
  def two
    o = [8]
    0.tap do |q|
      begin
        a = super() { |x| next 0 if x == 2; x * 10 }
        o = a
      ensure
        o << 9
      end
    end
    o
  end
end
p EnsureAround.new.two

class EnsureInnerTap < Base
  def two
    o = [8]
    0.tap do |q|
      1.tap do |w|
        begin
          a = super() { |x| next 0 if x == 2; x * 10 }
          o = a
        ensure
          o << w
        end
      end
    end
    o
  end
end
p EnsureInnerTap.new.two

# the tap block's own next, in the argument of a call after the super
class BesideCall < Base
  def from(n)
    o = [8]
    0.tap do |q|
      a = super(1) { |x| next 0 if x == 2; x * 10 }
      b = twice((next if n == 0; n)) { |x| x }
      o = a + b
    end
    o
  end
end
p BesideCall.new.from(0)
p BesideCall.new.from(5)
