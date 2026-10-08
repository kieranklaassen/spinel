# A method reached only through a child's `super` is called at no site of its
# own: the blocks its `yield` runs are the ones the child is called with, and
# they answer a different type at each site.
class Reader
  def read(key)
    value = fetch(key) { |k| yield k }
    [value, key]
  end
  def fetch(key) = yield(key)
end
class Cached < Reader
  def read(key) = super
end
p Cached.new.read(2) { |k| nil }
p Cached.new.read(3) { |k| k.to_s }
p Cached.new.read(4) { |k| k * 2 }

# an initialize, the String site first
class Field
  attr_reader :value
  def initialize(raw)
    @value = convert(raw) { |r| yield r }
  end
  def convert(raw) = yield(raw)
end
class Column < Field
  def initialize(raw) = super(raw)
end
p Column.new(3) { |r| r.to_s }.value
p Column.new(2) { |r| nil }.value
p Column.new(4) { |r| r * 2 }.value

# two links; the value in a local, and under an ensure
class Step
  def call(n)
    out = yield(n)
    out
  end
  def guarded(n)
    begin
      yield(n)
    ensure
      @done = true
    end
  end
end
class Logged < Step
  def call(n) = super
  def guarded(n) = super
end
class Timed < Logged
  def call(n) = super
  def guarded(n) = super
end
p Timed.new.call(1) { |n| :one }
p Timed.new.call(2) { |n| n + 1 }
p Timed.new.guarded(1) { |n| n > 0 }
p Timed.new.guarded(2) { |n| n * 10 }
