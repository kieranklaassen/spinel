# A block's value can be a call, with no block, to a method that yields under
# block_given?. Such a method has no function of its own: it is spliced at
# each call, whether or not the call hands it a block, and the statement form
# of that splice is a plain compound with no value. Read as the block's value
# it gave
#
#   error: void value not ignored as it ought to be
#
# Enumerable#minmax is such a method when its receiver is boxed.
rows = [[3, 1, 2], [5, 4], [6]]
p rows.flat_map { |r| r.minmax }
p rows.flat_map(&:minmax)
p rows.any? { |r| r.minmax }
p rows.all?(&:minmax)
p rows.none? { |r| r.minmax }
p rows.one? { |r| r.minmax }
p rows.count { |r| r.minmax }
p rows.find { |r| r.minmax }
p rows.find_index { |r| r.minmax }
p rows.filter_map { |r| r.minmax }
p [[3, 1, 2], [5, 4], [6]].drop_while { |r| r.minmax }
p [[3, 1, 2], [5, 4], [6]].take_while { |r| r.minmax }
p rows.partition { |r| r.minmax }
p rows.group_by { |r| r.minmax }.to_a
p [["b", "a"], [1.5, 0.5]].flat_map { |r| r.minmax }
# grep and grep_v are two more
p rows.flat_map { |r| r.grep(Integer) }
p rows.find { |r| r.grep_v(Integer) }

# A method of the program: called with a block it yields, without one it
# answers for itself.
def scaled(n)
  if block_given?
    yield n
  else
    n * 10
  end
end

def label(n)
  return yield(n) if block_given?
  "n#{n}"
end

class Pairs
  def self.of(n)
    if block_given?
      yield n
    else
      [n, n]
    end
  end

  def half(n)
    if block_given?
      yield n
    else
      n / 2.0
    end
  end
end

def keep(n)
  v = yield n
  v
end

def pass(n)
  yield n
end

def yes?(n)
  if yield(n)
    "yes"
  else
    "no"
  end
end

def gather(n)
  out = []
  out << yield(n)
  out << yield(n + 1)
  out
end

class Held
  attr_reader :v

  def initialize(n)
    @v = yield n
  end
end

pairs = Pairs.new
p keep(3) { |x| scaled(x) }
p keep(3) { |x| label(x) }
p keep(3) { |x| Pairs.of(x) }
p keep(3) { |x| pairs.half(x) }
p pass(4) { |x| scaled(x) }
p pass(4) { |x| label(x) }
p yes?(5) { |x| scaled(x) }
p gather(6) { |x| Pairs.of(x) }
p gather(6) { |x| label(x) }
p Held.new(7) { |x| scaled(x) }.v
p Held.new(7) { |x| Pairs.of(x) }.v

# under a builtin's yield
nums = [12, 7, 0]
p nums.flat_map { |x| Pairs.of(x) }
p nums.count { |x| scaled(x) }
p nums.find { |x| label(x) }
p nums.filter_map { |x| scaled(x) }
p nums.group_by { |x| label(x) }.to_a
p nums.any? { |x| pairs.half(x) }

# after other statements of the block
p keep(8) { |x| y = x + 1; scaled(y) }

# and with a block of its own, as before
p keep(3) { |x| scaled(x) { |y| y + 1 } }
p nums.flat_map { |x| Pairs.of(x) { |y| [y] } }
