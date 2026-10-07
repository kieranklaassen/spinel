module Walk
  def each
    yield 1
    yield 2
  end
  def label(prefix = "w", suffix: "!") = prefix + suffix
end
module Twice
  include Walk
  def each
    yield 10
    yield 20
    yield 30
  end
  def label(prefix = "t", *rest, suffix: "?") = prefix + rest.join + suffix
end
class Bag
  include Twice
  include Enumerable
end
class Sack
  include Twice
  include Walk
end
s = Sack.new
s.each { |x| p x }
p s.label, s.label("a"), s.label("a", "b", suffix: "#")
b = Bag.new
p b.map { |x| x + 1 }
