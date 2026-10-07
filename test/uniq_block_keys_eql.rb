# uniq with a block keeps the first element of each key, and compares the
# keys as uniq without a block compares the elements, by eql?: 1 and 1.0
# are two keys, and a class with == alone makes none.
class Tag
  attr_reader :n
  def initialize(n) = @n = n
  def ==(other) = other.is_a?(Tag) && n == other.n
end
class Key
  attr_reader :n
  def initialize(n) = @n = n
  def ==(other) = other.is_a?(Key) && n == other.n
  alias eql? ==
  def hash = n.hash
end

p [1, 2, 3].uniq { |x| x.odd? ? 1 : 1.0 }
p [1, 2, 3].uniq { |x| [x.odd? ? 1 : 1.0] }
p [1, 2, 3].uniq { |x| Tag.new(1) }
p [1, 2, 3].uniq { |x| Key.new(1) }
p [1, 2, 3, 4].uniq { |x| x.even? }
p %w[a B b].uniq { |s| s.downcase }
p [1, 2, 3, 4].uniq { |x| x.odd? ? nil : false }
p [1, 2, 3, 4].uniq { |x| x.odd? ? :a : "a" }

mixed = [1, "a", 2, 3]
p mixed.uniq { |x| x == 1 ? 1 : 1.0 }
p mixed.each_slice(2).uniq { |pair| pair[0] == 1 ? 2 : 2.0 }.size

kept = [1, 2, 3]
kept.uniq! { |x| x.odd? ? 1 : 1.0 }
p kept

p({ a: 1, b: 2, c: 3 }.uniq { |_, v| v.odd? ? 1 : 1.0 })
p (1..4).uniq { |x| x.odd? ? 1 : 1.0 }
